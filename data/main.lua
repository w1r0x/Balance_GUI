-- Improved version of dofile()
function include(name)
	dofile(application:getDataDirectory() .. name)
end

function onInit()
	-- make aliases to singleton objects
	application = Application:getSingleton()
	balance = Balance:getSingleton()
	graphics = Graphics:getSingleton()
	keyboard = Keyboard:getSingleton()
	mouse = Mouse:getSingleton()
	resourceManager = ResourceManager:getSingleton()
	resourceQueue = ResourceQueue:getSingleton()

	-- load translations
	include("i18n/en.lua")
	include("i18n/ru.lua")
	include("i18n/cn.lua")

	-- load scripts
	include("scripts/common.lua")
	include("scripts/main_screen.lua")
	include("scripts/start_screen.lua")
	include("scripts/layout_menu.lua")
	include("scripts/disk_menu.lua")
	include("scripts/keyboard.lua")
	include("scripts/balance_progress.lua")
	include("scripts/main_menu.lua")
	include("scripts/message.lua")
	include("scripts/wizard.lua")

	-- load the system profile
	profile = Profile("")

	-- configure the virtual screen
	graphics:setScreenSize(SCREEN_WIDTH, SCREEN_HEIGHT)

	-- disable vertical synchronization
	--graphics:setVSync(false)

	-- set the current language
	setLanguage(profile:getInt("language", 0))

	-- initialize the application
	onMainScreenInit()
	onStartScreenInit()
	onLayoutMenuInit()
	onDiskMenuInit()
	onKeyboardInit()
	onBalanceProgressInit()
	onMainMenuInit()
	onWizardInit();
	onMessageInit()

	-- show/hide mouse
	if profile:getInt("input_dev") == 2 then
		mouse:hideCursor()
	end

	-- show the start screen
	showStartScreen()

	-- show warning if touchscreen not found
	if profile:getInt("input_dev") == 0 then
		showMessage(tr("{no_touchscreen_text}"), MESSAGE_OK, MESSAGE_NO_TOUCHSCREEN)
	end
end

function onUpdate(delta)
	-- clear screen
	graphics:clear(0.0, 0.0, 0.0)

	-- track balance state/substate changes
	local newBalanceState = balance:getIntParam("state")
	local newBalanceSubstate = balance:getIntParam("substate")

	-- handle state changes
	if newBalanceState == STATE_IDLE or newBalanceState == STATE_RULER then
		hideBalanceProgress()
		hideWizard()
	elseif newBalanceState == STATE_BALANCE or (newBalanceState >= STATE_BALANCE_CAL0 and newBalanceState <= STATE_BALANCE_CAL3) then
		if newBalanceSubstate == BALANCE_IDLE then
			hideBalanceProgress()
			showWizard()
		elseif newBalanceSubstate == BALANCE_WAIT_COVER then
			hideBalanceProgress()
			hideWizard()
		elseif newBalanceSubstate >= BALANCE_START and newBalanceSubstate < BALANCE_AUTO_ROTATION then
			showBalanceProgress()
			hideWizard()
		else
			hideBalanceProgress()
			hideWizard()
		end
	elseif newBalanceState >= STATE_RULER_CAL0 and newBalanceState <= STATE_RULER_CAL3 then
		hideBalanceProgress()
		showWizard()
	end

	-- make beeps on certain events
	if newBalanceState == STATE_IDLE and balanceState == STATE_BALANCE and not stopPressed then
		soundBalanceSuccess:play()
	elseif newBalanceState == STATE_RULER and newBalanceSubstate == RULER_WAIT and balanceState == STATE_RULER and (balanceSubstate == RULER_MEASURE or balanceSubstate == RULER_MEASURE_L) or
		newBalanceState == STATE_RULER_CAL0 and newBalanceSubstate == RULER_WAIT and balanceState == STATE_RULER_CAL0 and (balanceSubstate == RULER_MEASURE or balanceSubstate == RULER_MEASURE_L) then
		soundRulerSuccess:play()
	end

	-- save new balance state
	balanceState = newBalanceState
	balanceSubstate = newBalanceSubstate

	-- update modules
	onMainScreenUpdate(delta)
	onStartScreenUpdate(delta)
	onLayoutMenuUpdate(delta)
	onDiskMenuUpdate(delta)
	onBalanceProgressUpdate(delta)
	onMainMenuUpdate(delta)
	onKeyboardUpdate(delta)
	onWizardUpdate(delta)
	onMessageUpdate(delta)

	-- show current FPS
	--fontSizes:drawText(30, 30, string.format("FPS = %.2f", graphics:getFPS()), 0, 0, 0)
end

function onMouseDown(x, y, key)
	-- ignore all mouse buttons except the left one
	if key ~= MOUSE_LEFT then
		return
	end

	-- set the mouse pressed flag
	mousePressed = true

	-- dispatch the event
	if not onMessageMouseDown(x, y, key) then
		if not onWizardMouseDown(x, y, key) then
			if not onKeyboardMouseDown(x, y, key) then
				if not onMainMenuMouseDown(x, y, key) then
					if not onBalanceProgressMouseDown(x, y, key) then
						if not onDiskMenuMouseDown(x, y, key) then
							if not onLayoutMenuMouseDown(x, y, key) then
								if not onStartScreenMouseDown(x, y, key) then
									onMainScreenMouseDown(x, y, key)
								end
							end
						end
					end
				end
			end
		end
	end
end

function onMouseUp(x, y, key)
	-- ignore all mouse buttons except the left one
	if key ~= MOUSE_LEFT then
		return
	end

	-- clear the mouse pressed flag
	mousePressed = false

	-- dispatch the event
	if not onMessageMouseUp(x, y, key) then
		if not onWizardMouseUp(x, y, key) then
			if not onKeyboardMouseUp(x, y, key) then
				if not onMainMenuMouseUp(x, y, key) then
					if not onBalanceProgressMouseUp(x, y, key) then
						if not onDiskMenuMouseUp(x, y, key) then
							if not onLayoutMenuMouseUp(x, y, key) then
								if not onStartScreenMouseUp(x, y, key) then
									onMainScreenMouseUp(x, y, key)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- start the game engine if running under external Lua interpreter
if not Application then
	local dataDir = arg[0]:match("^.*[\\/]") or "./"
	GAME_COMMAND_LINE = "-d \"" .. dataDir .. "\""
	require("Balance")
end
