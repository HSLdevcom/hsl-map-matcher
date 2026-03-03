-- Bus profile

api_version = 4

Set = require("lib/set")
Sequence = require("lib/sequence")
Handlers = require("lib/way_handlers")
Relations = require("lib/relations")
TrafficSignal = require("lib/traffic_signal")
find_access_tag = require("lib/access").find_access_tag
limit = require("lib/maxspeed").limit
Utils = require("lib/utils")
Measure = require("lib/measure")

local mocks = {}

local function get_tag(way, key)
	local way_id = tostring(way:id())
	if mocks[way_id] and mocks[way_id][key] then
		return mocks[way_id][key]
	end
	return way:get_value_by_key(key)
end

local current_date = os.date("%Y%m%d")
local current_year = tonumber(os.date("%Y"))
local current_month = tonumber(os.date("%m"))
local current_day = tonumber(os.date("%d"))

-- Helper function to parse OSM date formats
-- Supports: "2025", "2025-11", "2025-11-03", "2025-11-03T12:00:00Z"
-- Returns: YYYYMMDD as number, or nil if invalid
function parse_date(date_str, is_end_date)
	if not date_str or date_str == "" then
		return nil
	end

	local year = tonumber(string.match(date_str, "^(%d%d%d%d)"))
	if not year then
		return nil
	end

	local month = tonumber(string.match(date_str, "%-(%d%d)"))
	if not month then
		if is_end_date then
			month = 12
		else
			month = 1
		end
	end

	local day = tonumber(string.match(date_str, "%-%d%d%-(%d%d)"))
	if not day then
		if is_end_date then
			local days_in_month = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
			day = days_in_month[month]
		else
			day = 1
		end
	end

	return year * 10000 + month * 100 + day
end

-- Check if a construction way should be allowed based on temporal tags
-- Logic:
--   - Construction with whitelisted construction value → always allow
--   - Construction with NO dates → avoid (assume actually under construction)
--   - Construction with opening_date in past → allow (stale construction tag, should be open)
--   - Construction with opening_date in future → avoid (not opened yet)
-- Returns true if construction way should be excluded, false if allowed
function should_exclude_construction(profile, way)
	local construction = get_tag(way, "construction")
	if construction and profile.construction_whitelist[construction] then
		return false
	end

	local opening_date_str = get_tag(way, "opening_date")

	if not opening_date_str or opening_date_str == "" then
		return true
	end

	if opening_date_str and opening_date_str ~= "" then
		local opening_date = parse_date(opening_date_str, false)
		if opening_date then
			if opening_date > tonumber(current_date) then
				return true
			else
				return false
			end
		end
	end

	return true
end

-- Check if a way should be filtered based on temporal tags
-- Returns true if way should be excluded, false otherwise
function should_exclude_by_date(way)
	local opening_date_str = get_tag(way, "opening_date")

	if opening_date_str and opening_date_str ~= "" then
		local opening_date = parse_date(opening_date_str, false)
		if opening_date and opening_date > tonumber(current_date) then
			return true -- Not opened yet
		end
	end

	return false
end

function setup()
	return {
		properties = {
			max_speed_for_map_matching = 180 / 3.6, -- 180kmph -> m/s
			-- For routing based on duration, but weighted for preferring certain roads
			-- weight_name                     = 'routability',
			-- For shortest duration without penalties for accessibility
			-- weight_name                     = 'duration',
			-- For shortest distance without penalties for accessibility
			weight_name = "distance",
			process_call_tagless_node = false,
			u_turn_penalty = 0,
			continue_straight_at_waypoint = true,
			use_turn_restrictions = false,
			left_hand_driving = false,
			traffic_light_penalty = 0,
		},

		default_mode = mode.driving,
		default_speed = 10,
		oneway_handling = true,
		side_road_multiplier = 0.8,
		turn_penalty = 7.5,
		speed_reduction = 0.8,
		turn_bias = 1.075,
		cardinal_directions = false,

		-- a list of suffixes to suppress in name change instructions. The suffixes also include common substrings of each other
		suffix_list = {},

		barrier_whitelist = Set({
			"gate",
			"lift_gate",
		}),

		access_tag_whitelist = Set({}),

		access_tag_blacklist = Set({}),

		-- tags disallow access to in combination with highway=service
		service_access_tag_blacklist = Set({}),

		restricted_access_tag_list = Set({}),

		access_tags_hierarchy = Sequence({}),

		service_tag_forbidden = Set({}),

		restrictions = Sequence({}),

		classes = Sequence({}),

		-- classes to support for exclude flags
		excludable = Sequence({}),

		avoid = Set({
			"construction",
			"proposed",
		}),

		speeds = Sequence({
			highway = {
				motorway = 90,
				motorway_link = 45,
				trunk = 85,
				trunk_link = 40,
				primary = 65,
				primary_link = 30,
				secondary = 55,
				secondary_link = 25,
				tertiary = 40,
				tertiary_link = 20,
				unclassified = 25,
				residential = 25,
				living_street = 10,
				service = 15,
			},
		}),

		service_penalties = {},

		restricted_highway_whitelist = Set({}),

		construction_whitelist = Set({
			"no",
			"widening",
			"minor",
		}),

		route_speeds = {},

		bridge_speeds = {},

		-- surface/trackype/smoothness
		-- values were estimated from looking at the photos at the relevant wiki pages

		-- max speed for surfaces
		surface_speeds = {},

		-- max speed for tracktypes
		tracktype_speeds = {},

		-- max speed for smoothnesses
		smoothness_speeds = {},

		-- http://wiki.openstreetmap.org/wiki/Speed_limits
		maxspeed_table_default = {},

		-- List only exceptions
		maxspeed_table = {},

		relation_types = Sequence({}),

		-- classify highway tags when necessary for turn weights
		highway_turn_classification = {},

		-- classify access tags when necessary for turn weights
		access_turn_classification = {},
	}
end

function process_node(profile, node, result, relations)
	-- parse access and barrier tags
	local access = find_access_tag(node, profile.access_tags_hierarchy)
	if access then
		if profile.access_tag_blacklist[access] and not profile.restricted_access_tag_list[access] then
			result.barrier = true
		end
	else
		local barrier = node:get_value_by_key("barrier")
		if barrier then
			--  check height restriction barriers
			local restricted_by_height = false
			if barrier == "height_restrictor" then
				if maxheight and profile.vehicle_height then
					local maxheight = Measure.get_max_height(node:get_value_by_key("maxheight"), node)
					restricted_by_height = maxheight and maxheight < profile.vehicle_height
				end
			end

			--  make an exception for rising bollard barriers
			local bollard = node:get_value_by_key("bollard")
			local rising_bollard = bollard and "rising" == bollard

			-- make an exception for lowered/flat barrier=kerb
			-- and incorrect tagging of highway crossing kerb as highway barrier
			local kerb = node:get_value_by_key("kerb")
			local highway = node:get_value_by_key("highway")
			local flat_kerb = kerb and ("lowered" == kerb or "flush" == kerb)
			local highway_crossing_kerb = barrier == "kerb" and highway and highway == "crossing"

			if
				not profile.barrier_whitelist[barrier]
					and not rising_bollard
					and not flat_kerb
					and not highway_crossing_kerb
				or restricted_by_height
			then
				result.barrier = true
			end
		end
	end

	-- check if node is a traffic light
	result.traffic_lights = TrafficSignal.get_value(node)
end

function process_way(profile, way, result, relations)
	-- the intial filtering of ways based on presence of tags
	-- affects processing times significantly, because all ways
	-- have to be checked.
	-- to increase performance, prefetching and intial tag check
	-- is done in directly instead of via a handler.

	-- in general we should  try to abort as soon as
	-- possible if the way is not routable, to avoid doing
	-- unnecessary work. this implies we should check things that
	-- commonly forbids access early, and handle edge cases later.

	-- data table for storing intermediate values during processing
	local data = {
		-- prefetch tags
		highway = get_tag(way, "highway"),
		railway = get_tag(way, "railway"),
	}

	-- perform an quick initial check and abort if the way is
	-- obviously not routable.
	-- highway or route tags must be in data table, bridge is optional
	if (not data.highway or data.highway == "") and (not data.railway or data.railway == "") then
		return
	end

	if data.highway == "construction" then
		if should_exclude_construction(profile, way) then
			return
		end
	else
		if should_exclude_by_date(way) then
			return
		end
	end

	handlers = Sequence({
		-- set the default mode for this profile. if can be changed later
		-- in case it turns we're e.g. on a ferry
		WayHandlers.default_mode,

		-- check various tags that could indicate that the way is not
		-- routable. this includes things like status=impassable,
		-- toll=yes and oneway=reversible
		WayHandlers.blocked_ways,
		WayHandlers.avoid_ways,

		-- check whether forward/backward directions are routable
		WayHandlers.oneway,

		-- compute speed taking into account way type, maxspeed tags, etc.
		WayHandlers.speed,

		-- set weight properties of the way
		WayHandlers.weights,
	})

	WayHandlers.run(profile, way, result, data, handlers, relations)
end

function process_turn(profile, turn)
	-- Use a sigmoid function to return a penalty that maxes out at turn_penalty
	-- over the space of 0-180 degrees.  Values here were chosen by fitting
	-- the function to some turn penalty samples from real driving.
	local turn_penalty = profile.turn_penalty
	local turn_bias = turn.is_left_hand_driving and 1. / profile.turn_bias or profile.turn_bias

	if turn.has_traffic_light then
		turn.duration = profile.properties.traffic_light_penalty
	end

	if turn.number_of_roads > 2 or turn.source_mode ~= turn.target_mode or turn.is_u_turn then
		if turn.angle >= 0 then
			turn.duration = turn.duration
				+ turn_penalty / (1 + math.exp(-((13 / turn_bias) * turn.angle / 180 - 6.5 * turn_bias)))
		else
			turn.duration = turn.duration
				+ turn_penalty / (1 + math.exp(-((13 * turn_bias) * -turn.angle / 180 - 6.5 / turn_bias)))
		end

		if turn.is_u_turn then
			turn.duration = turn.duration + profile.properties.u_turn_penalty
		end
	end

	-- for distance based routing we don't want to have penalties based on turn angle
	if profile.properties.weight_name == "distance" then
		turn.weight = 0
	else
		turn.weight = turn.duration
	end

	if profile.properties.weight_name == "routability" then
		-- penalize turns from non-local access only segments onto local access only tags
		if not turn.source_restricted and turn.target_restricted then
			turn.weight = constants.max_turn_weight
		end
	end
end

return {
	setup = setup,
	process_way = process_way,
	process_node = process_node,
	process_turn = process_turn,
}
