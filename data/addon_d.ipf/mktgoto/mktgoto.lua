local mktGoto = {}
function MARKET_GOTO_PAGE(page)
	local frame = ui.GetFrame("market");
	if (frame == nil) or (page == nil) then
		CHAT_SYSTEM("[MARKET GOTO PAGE] Open market first.")
		return false
	else
		local pagecontrol = GET_CHILD(frame, "pageControl", "ui::CPageController");
		local MaxPage = pagecontrol:GetMaxPage();
		page = tonumber(page) or page;
		if (page == "last") then
			page = MaxPage
		elseif (page == "first") then
			page = 0
		end
		if (page >= MaxPage) then
			page = MaxPage-1;
		elseif (page < 1) then
			page = 0;
		elseif (tonumber(page) ~= nil) then
			page = page-1;
		else
			CHAT_SYSTEM("[MARKET GOTO PAGE] Not a valid page")
			return false
		end
		if page ~= nil then
			MARKET_FIND_PAGE(frame, page);
		end
		return true
	end
	return false
end

function MKTGOTO_ON_INIT(addon, frame)
	if (mktGoto.UI_CHAT == nil) then
		mktGoto.UI_CHAT = UI_CHAT;
	end
	UI_CHAT = function(msg)
		local arg = string.split(msg, " ");
		if (arg[1] == "/goto") then
			if (arg[2] == nil) then
				CHAT_SYSTEM("[MARKET GOTO PAGE] Should set a page after /goto{nl}Usage: /goto [number|first|last]")
			else
				MARKET_GOTO_PAGE(arg[2])
			end
		end
		mktGoto.UI_CHAT(msg);
	end
end
