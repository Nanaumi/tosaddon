--dofile("../data/addon_d/marketnames/marketnames.lua");

function MARKETNAMES_ON_INIT(addon, frame)
	local acutil = require("acutil");
	acutil.setupHook(MARKET_DRAW_CTRLSET_EXPORB_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_EXPORB");
	acutil.setupHook(MARKET_DRAW_CTRLSET_CARD_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_CARD");
	acutil.setupHook(MARKET_DRAW_CTRLSET_GEM_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_GEM");
	acutil.setupHook(MARKET_DRAW_CTRLSET_ACCESSORY_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_ACCESSORY");
	acutil.setupHook(MARKET_DRAW_CTRLSET_RECIPE_SEARCHLIST_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_RECIPE_SEARCHLIST");
	acutil.setupHook(MARKET_DRAW_CTRLSET_RECIPE_SEARCH_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_RECIPE_SEARCH");
	acutil.setupHook(MARKET_DRAW_CTRLSET_RECIPE_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_RECIPE");
	acutil.setupHook(MARKET_DRAW_CTRLSET_EQUIP_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_EQUIP");
	acutil.setupHook(MARKET_DRAW_CTRLSET_DEFAULT_SELLER_HOOKED, "MARKET_DRAW_CTRLSET_DEFAULT");

	addon:RegisterMsg("GAME_START_3SEC", "MARKETNAMES_LOAD");
	addon:RegisterMsg("FPS_UPDATE", "MARKETNAMES_UPDATE");
end

function MARKETNAMES_LOAD()
	_G["MARKETNAMES_PREVIOUS_SERVER_ID"] = _G["MARKETNAMES_CURRENT_SERVER_ID"];
	_G["MARKETNAMES_CURRENT_SERVER_ID"] = MARKETNAMES_GET_SERVER_ID();

	if _G["MARKETNAMES_CURRENT_SERVER_ID"] ~= _G["MARKETNAMES_PREVIOUS_SERVER_ID"] then
		_G["MARKETNAMES"] = nil;
	end

	if _G["MARKETNAMES"] ~= nil then
		return;
	end

	_G["MARKETNAMES"] = {};

	for line in io.lines(MARKETNAMES_GET_FILENAME()) do
		local cid, fullName = line:match("([^=]+)=([^=]+)");

		local marketName = _G["MARKETNAMES"][cid];

		if marketName == nil then
			local characterName, familyName = MARKETNAMES_SPLIT_NAME(fullName);

			marketName = {};
			marketName.characterName = characterName;
			marketName.familyName = familyName;

			_G["MARKETNAMES"][cid] = marketName;
		end
	end
end

function MARKETNAMES_SAVE()
	local file, error = io.open(MARKETNAMES_GET_FILENAME(), "w");

	if error then
		CHAT_SYSTEM("Failed to write marketnames file!");
		return;
	end

	for k,v in pairs(_G["MARKETNAMES"]) do
		file:write(k .. "=" .. v.characterName .. " " .. v.familyName .. "\n");
	end

	file:flush();
	file:close();
end

function MARKETNAMES_SPLIT_NAME(fullName)
	local characterName, familyName = "";
	local tokenCount = 1;

	for token in string.gmatch(fullName, "%S+") do
		if tokenCount == 1 then
			characterName = token;
		elseif tokenCount == 2 then
			familyName = token;
		end

		tokenCount = tokenCount + 1;
	end

	return characterName, familyName;
end

function MARKETNAMES_UPDATE(frame, msg, argStr, argNum)
	MARKETNAMES_LOAD();

	local addedName = false;
	local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 1000000, 'ALL');

	for i = 1, selectedObjectsCount do
		local handle = GetHandle(selectedObjects[i]);

		if handle ~= nil then
			if info.IsPC(handle) == 1 then
				local cid = info.GetCID(handle);
				local marketName = _G["MARKETNAMES"][cid];
				local characterName = info.GetName(handle);
				local familyName = info.GetFamilyName(handle);

				if marketName == nil then
					marketName = {};
					marketName.characterName = characterName;
					marketName.familyName = familyName;
					_G["MARKETNAMES"][cid] = marketName;
					addedName = true;
				end
			end
		end
	end

	if addedName then
		MARKETNAMES_SAVE();
	end
end

function MARKETNAMES_GET_SERVER_ID()
	local f = io.open('../release/user.xml', "rb");
	local content = f:read("*all");
	f:close();
	return content:match('RecentServer="(.-)"');
end

function MARKETNAMES_GET_FILENAME()
	return "../addons/marketnames/marketnames-" .. MARKETNAMES_GET_SERVER_ID() .. ".txt";
end

function MARKETNAMES_PRINT()
	local total = 0;

	for k,v in pairs(_G["MARKETNAMES"]) do
		print(k .. "=" .. v.characterName .. " " .. v.familyName);
		total = total + 1;
	end

	print(total);
end

local function MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem)
	local pic = GET_CHILD_RECURSIVELY(ctrlSet, "pic");
	SET_SLOT_ITEM_CLS(pic, itemObj)
	SET_ITEM_TOOLTIP_ALL_TYPE(pic:GetIcon(), marketItem, itemObj.ClassName, "market", marketItem.itemType, marketItem:GetMarketGuid());

    SET_SLOT_STYLESET(pic, itemObj)
    if itemObj.MaxStack > 1 then
		SET_SLOT_COUNT_TEXT(pic, marketItem.count, '{s16}{ol}{b}');
	end
end

function MARKET_DRAW_CTRLSET_DEFAULT_SELLER_HOOKED(frame, isShowLevel)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "defaultTitle")
	local defaultTitle_level = GET_CHILD_RECURSIVELY(frame, "defaultTitle_level")
	if isShowLevel ~= nil and isShowLevel == false then
		defaultTitle_level:ShowWindow(0)
	else
		defaultTitle_level:ShowWindow(1)
	end

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_default", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		if itemObj.GroupName == "ExpOrb" then
			local curExp, maxExp = GET_LEGENDEXPPOTION_EXP(itemObj)
			local expPoint = 0
			if maxExp ~= nil and maxExp ~= 0 then
				expPoint = curExp / maxExp * 100
			else 
				expPoint = 0
			end
			local expStr = string.format("%.2f", expPoint)

			MARKET_SET_EXPORB_ICON(ctrlSet, curExp, maxExp, itemObj)
		end

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local level = ctrlSet:GetChild("level");
		local levelValue = ""
		if itemObj.GroupName == "Gem" then
			levelValue = GET_ITEM_LEVEL_EXP(itemObj)
		elseif itemObj.GroupName == "Card" then
			levelValue = itemObj.Level
		elseif itemObj.ItemType == "Equip" and itemObj.GroupName ~= "Premium" then
			levelValue = itemObj.UseLv
		end
		level:SetTextByKey("value", levelValue);

		local price_num = ctrlSet:GetChild("price_num");
		price_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
		price_num:SetUserValue("Price", marketItem.sellPrice);

		local price_text = ctrlSet:GetChild("price_text");
		price_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local editCount = GET_CHILD_RECURSIVELY(ctrlSet, "count")
			editCount:SetMinNumber(1)
			editCount:SetMaxNumber(marketItem.count)
			editCount:SetText("1")
			editCount:SetNumChangeScp("MARKET_CHANGE_COUNT");
			ctrlSet:SetUserValue("minItemCount", 1)
			ctrlSet:SetUserValue("maxItemCount", marketItem.count)
			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end


function MARKET_DRAW_CTRLSET_EQUIP_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "equipTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_equip", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);
		ctrlSet:SetUserValue("optionIndex", 0)

		local inheritanceItem = GetClass('Item', itemObj.InheritanceItemName)
		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = GET_CHILD_RECURSIVELY(ctrlSet, "name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local level = GET_CHILD_RECURSIVELY(ctrlSet, "level");
		level:SetTextByKey("value", itemObj.UseLv);

		--ATK, MATK, DEF 
		local atkdefImageSize = ctrlSet:GetUserConfig("ATKDEF_IMAGE_SIZE")
 		local basicProp = 'None';
 		local atkdefText = "";
    	if itemObj.BasicTooltipProp ~= 'None' then
    		local basicTooltipPropList = StringSplit(itemObj.BasicTooltipProp, ';');
    	    for i = 1, #basicTooltipPropList do
    	        basicProp = basicTooltipPropList[i];
    	        if basicProp == 'ATK' then
				    typeiconname = 'test_sword_icon'
					typestring = ScpArgMsg("Melee_Atk")
					if TryGetProp(itemObj, 'EquipGroup') == "SubWeapon" then
						typestring = ScpArgMsg("PATK_SUB")
					end
					arg1 = itemObj.MINATK;
					arg2 = itemObj.MAXATK;
				elseif basicProp == 'MATK' then
				    typeiconname = 'test_sword_icon'
					typestring = ScpArgMsg("Magic_Atk")
					arg1 = itemObj.MATK;
					arg2 = itemObj.MATK;
				else
					typeiconname = 'test_shield_icon'
					typestring = ScpArgMsg(basicProp);
					if itemObj.RefreshScp ~= 'None' then
						local scp = _G[itemObj.RefreshScp];
						if scp ~= nil then
							scp(itemObj);
						end
					end
					
					arg1 = TryGetProp(itemObj, basicProp);
					arg2 = TryGetProp(itemObj, basicProp);
				end

				local tempStr = string.format("{img %s %d %d}", typeiconname, atkdefImageSize, atkdefImageSize)
				local tempATKDEF = ""
				if arg1 == arg2 or arg2 == 0 then
					tempATKDEF = " " .. arg1
				else
					tempATKDEF = " " .. arg1 .. "~" .. arg2
				end

				if i == 1 then
					atkdefText = atkdefText .. tempStr .. typestring .. tempATKDEF
				else
					atkdefText = atkdefText .. "{nl}" .. tempStr .. typestring .. tempATKDEF
				end
    	    end
   		end

    	local atkdef = GET_CHILD_RECURSIVELY(ctrlSet, "atkdef");
		atkdef:SetTextByKey("value", atkdefText);

		--SOCKET

		local socket = GET_CHILD_RECURSIVELY(ctrlSet, "socket")
		
		local needAppraisal = TryGetProp(itemObj, "NeedAppraisal");
		local needRandomOption = TryGetProp(itemObj, "NeedRandomOption");
			local maxSocketCount = itemObj.MaxSocket
			local drawFlag = 0
			if maxSocketCount > 3 then
				drawFlag = 1
			end

			local curCount = 1
			local socketText = ""
			local tempStr = ""
			for i = 0, maxSocketCount - 1 do
				if itemObj['Socket_' .. i] > 0 then
					
					local isEquip = itemObj['Socket_Equip_' .. i]
					if isEquip == 0 then
						tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_EMPTY")
						if drawFlag == 1 and curCount % 2 == 1 then
							socketText = socketText .. tempStr
						else
							socketText = socketText .. tempStr .. "{nl}"
						end
					else
						local gemClass = GetClassByType("Item", isEquip);
						if gemClass.ClassName == 'gem_circle_1' then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_RED")
						elseif gemClass.ClassName == 'gem_square_1' then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_BLUE")
						elseif gemClass.ClassName == 'gem_diamond_1' then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_GREEN")
						elseif gemClass.ClassName == 'gem_star_1' then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_YELLOW")
						elseif gemClass.ClassName == 'gem_White_1' then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_WHITE")
						elseif gemClass.EquipXpGroup == "Gem_Skill" then
							tempStr = ctrlSet:GetUserConfig("SOCKET_IMAGE_MONSTER")
						end
						
						local gemLv = GET_ITEM_LEVEL_EXP(gemClass, itemObj['SocketItemExp_' .. i])
						tempStr = tempStr .. "Lv" .. gemLv

						if drawFlag == 1 and curCount % 2 == 1 then
							socketText = socketText .. tempStr
						else
							socketText = socketText .. tempStr .. "{nl}"
						end
					end									
				end
				curCount = curCount + 1
			end
			socket:SetTextByKey("value", socketText)

		-- POTENTIAL

		local potential = GET_CHILD_RECURSIVELY(ctrlSet, "potential");
		if needAppraisal == 1 then
			potential:SetTextByKey("value1", "?")
			potential:SetTextByKey("value2", "?")			
		else
			potential:SetTextByKey("value1", itemObj.PR)
			potential:SetTextByKey("value2", itemObj.MaxPR)
		end

		-- OPTION

		local originalItemObj = itemObj
		if inheritanceItem ~= nil then
			itemObj = inheritanceItem
		end

		if needAppraisal == 1 or needRandomOption == 1 then
			SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, '{@st66b}'..ScpArgMsg("AppraisalItem"))
		end

		local basicList = GET_EQUIP_TOOLTIP_PROP_LIST(itemObj);
	    local list = {};
    	local basicTooltipPropList = StringSplit(itemObj.BasicTooltipProp, ';');
    	for i = 1, #basicTooltipPropList do
    	    local basicTooltipProp = basicTooltipPropList[i];
    	    list = GET_CHECK_OVERLAP_EQUIPPROP_LIST(basicList, basicTooltipProp, list);
    	end

		local list2 = GET_EUQIPITEM_PROP_LIST();
		local cnt = 0;
		local class = GetClassByType("Item", itemObj.ClassID);

		local maxRandomOptionCnt = MAX_OPTION_EXTRACT_COUNT;
		local randomOptionProp = {};
		for i = 1, maxRandomOptionCnt do
			if itemObj['RandomOption_'..i] ~= 'None' then
				randomOptionProp[itemObj['RandomOption_'..i]] = itemObj['RandomOptionValue_'..i];
			end
		end

		for i = 1 , #list do
			local propName = list[i];
			local propValue = class[propName];

			local needToShow = true;
			for j = 1, #basicTooltipPropList do
				if basicTooltipPropList[j] == propName then
					needToShow = false;
				end
			end

			if needToShow == true and propValue ~= 0 and randomOptionProp[propName] == nil then -- 랜덤 옵션이랑 겹치는 프로퍼티는 여기서 출력하지 않음
				if  itemObj.GroupName == 'Weapon' then
					if propName ~= "MINATK" and propName ~= 'MAXATK' then
						local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);			
						SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
					end
				elseif  itemObj.GroupName == 'Armor' then
					if itemObj.ClassType == 'Gloves' then
						if propName ~= "HR" then
							local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
							SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
						end
					elseif itemObj.ClassType == 'Boots' then
						if propName ~= "DR" then
							local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
							SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
						end
					else
						if propName ~= "DEF" then
							local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
							SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
						end
					end
				else
					local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
					SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
				end
			end
		end

		for i = 1 , 3 do
			local propName = "HatPropName_"..i;
			local propValue = "HatPropValue_"..i;
			if itemObj[propValue] ~= 0 and itemObj[propName] ~= "None" then
				local opName = string.format("[%s] %s", ClMsg("EnchantOption"), ScpArgMsg(itemObj[propName]));
				local strInfo = ABILITY_DESC_PLUS(opName, itemObj[propValue]);
				SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
			end
		end
	
		for i = 1 , maxRandomOptionCnt do
		    local propGroupName = "RandomOptionGroup_"..i;
			local propName = "RandomOption_"..i;
			local propValue = "RandomOptionValue_"..i;
			local clientMessage = 'None'

			local propItem = originalItemObj

			if propItem[propGroupName] == 'ATK' then
			    clientMessage = 'ItemRandomOptionGroupATK'
			elseif propItem[propGroupName] == 'DEF' then
			    clientMessage = 'ItemRandomOptionGroupDEF'
			elseif propItem[propGroupName] == 'UTIL_WEAPON' then
			    clientMessage = 'ItemRandomOptionGroupUTIL'
			elseif propItem[propGroupName] == 'UTIL_ARMOR' then
			    clientMessage = 'ItemRandomOptionGroupUTIL'
			elseif propItem[propGroupName] == 'UTIL_SHILED' then
			    clientMessage = 'ItemRandomOptionGroupUTIL'
			elseif propItem[propGroupName] == 'STAT' then
			    clientMessage = 'ItemRandomOptionGroupSTAT'
			end
			
			if propItem[propValue] ~= 0 and propItem[propName] ~= "None" then
				local opName = string.format("%s %s", ClMsg(clientMessage), ScpArgMsg(propItem[propName]));
				local strInfo = ABILITY_DESC_NO_PLUS(opName, propItem[propValue], 0);
				SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
			end
		end

        if originalItemObj['RandomOptionRareValue'] ~= 0 and originalItemObj['RandomOptionRare'] ~= "None" then
			local strInfo = _GET_RANDOM_OPTION_RARE_CLIENT_TEXT(originalItemObj['RandomOptionRare'], originalItemObj['RandomOptionRareValue']);
            if strInfo ~= nil then
			    SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
            end
		end

		for i = 1 , #list2 do
			local propName = list2[i];
			local propValue = itemObj[propName];
			if propValue ~= 0 then
				local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), itemObj[propName]);
				SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
			end
		end

		if itemObj.OptDesc ~= nil and itemObj.OptDesc ~= 'None' then
			SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, itemObj.OptDesc);
		end

		if inheritanceItem == nil then
		if itemObj.IsAwaken == 1 then
			local opName = string.format("[%s] %s", ClMsg("AwakenOption"), ScpArgMsg(itemObj.HiddenProp));
			local strInfo = ABILITY_DESC_PLUS(opName, itemObj.HiddenPropValue);
				SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
			end
		else
			if inheritanceItem.IsAwaken == 1 then
				local opName = string.format("[%s] %s", ClMsg("AwakenOption"), ScpArgMsg(inheritanceItem.HiddenProp));
				local strInfo = ABILITY_DESC_PLUS(opName, inheritanceItem.HiddenPropValue);
				SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
			end
		end

		if itemObj.ReinforceRatio > 100 then
			local opName = ClMsg("ReinforceOption");
			local strInfo = ABILITY_DESC_PLUS(opName, math.floor(10 * itemObj.ReinforceRatio/100));
			SET_MARKET_EQUIP_CTRLSET_OPTION_TEXT(ctrlSet, strInfo);
		end



		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		-- 내 판매리스트 처리

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = GET_CHILD_RECURSIVELY(ctrlSet, "reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = GET_CHILD_RECURSIVELY(ctrlSet, "totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = GET_CHILD_RECURSIVELY(ctrlSet, "totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local totalPrice_num = GET_CHILD_RECURSIVELY(ctrlSet, "totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = GET_CHILD_RECURSIVELY(ctrlSet, "totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, true, false)

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end

function MARKET_DRAW_CTRLSET_RECIPE_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "recipeTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_recipe", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);
		ctrlSet:SetUserValue("itemClassName", itemObj.ClassName)

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local count = ctrlSet:GetChild("count");
		count:SetTextByKey("value", marketItem.count);
		
		local price_num = ctrlSet:GetChild("price_num");
		price_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
		price_num:SetUserValue("Price", marketItem.sellPrice);

		local price_text = ctrlSet:GetChild("price_text");
		price_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local editCount = GET_CHILD_RECURSIVELY(ctrlSet, "count")
			editCount:SetMinNumber(1)
			editCount:SetMaxNumber(marketItem.count)
			editCount:SetText("1")
			editCount:SetNumChangeScp("MARKET_CHANGE_COUNT");
			ctrlSet:SetUserValue("minItemCount", 1)
			ctrlSet:SetUserValue("maxItemCount", marketItem.count)
			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("marketItemGuid", marketItem:GetMarketGuid())
		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	local itemlistHeight = itemlist:GetHeight()
	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);
	if frame:GetUserIValue("isRecipeSearching") == 2 then
		frame:SetUserValue("isRecipeSearching", 1)
		local maxPage_recipe = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
		local curPage_recipe = session.market.GetCurPage();
		local pagecontrol_recipe = GET_CHILD(frame, 'pagecontrol_recipe', 'ui::CPageController')
	    if maxPage_recipe < 1 then
	        maxPage_recipe = 1;
	    end

		pagecontrol_recipe:SetMaxPage(maxPage_recipe);
		pagecontrol_recipe:SetCurPage(curPage_recipe);
	end
	itemlist:Resize(itemlist:GetWidth(), itemlistHeight)
	
	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end

function MARKET_DRAW_CTRLSET_RECIPE_SEARCH_SELLER_HOOKED(ctrlSet)
	local frame = ui.GetFrame("market")
	if frame == nil then
		return
	end

	local searchBtn = GET_CHILD_RECURSIVELY(ctrlSet, "searchBtn");
	ui.DisableForTime(searchBtn, 1.5);

	frame:SetUserValue("isRecipeSearching", 1)
	frame:SetUserValue("searchListIndex", 0)

	local recipeBG = GET_CHILD_RECURSIVELY(frame, "market_midle3")
	local recipeGbox = GET_CHILD_RECURSIVELY(frame, "itemListGbox")
	local market_low = GET_CHILD_RECURSIVELY(frame, "market_low")
	local materialBG = GET_CHILD_RECURSIVELY(frame, "market_material_bg")
	local materialGbox = GET_CHILD_RECURSIVELY(frame, "recipeSearchGbox")
	local pageControl = GET_CHILD_RECURSIVELY(frame, "pagecontrol")
	local recipePageControl = GET_CHILD_RECURSIVELY(frame, "pagecontrol_recipe")
	local recipeSearchTitle = GET_CHILD_RECURSIVELY(frame, "recipeSearchTitle")
	local recipeSearchTemp = GET_CHILD_RECURSIVELY(frame, "recipeSearchTemp")

	materialBG:ShowWindow(1)
	materialGbox:ShowWindow(1)
	recipeSearchTitle:ShowWindow(1)
	materialGbox:SetUserValue("yPos", 0)
	materialGbox:RemoveAllChild();

	recipeBG:Resize(recipeBG:GetWidth(), market_low:GetHeight()/3 + 13)
	recipeGbox:Resize(recipeGbox:GetWidth(), market_low:GetHeight()/3 - 22)
	recipePageControl:ShowWindow(1)
	recipeSearchTemp:ShowWindow(1)
	pageControl:ShowWindow(0)

	local itemClassName = ctrlSet:GetUserValue("itemClassName")
	materialGbox:SetUserValue("itemClassName", itemClassName)
	local recipeCls = GetClass("Recipe", itemClassName)
	if recipeCls == nil then
		return
	end

	local materialList = ""
	local maxRecipeMaterialCount = MAX_RECIPE_MATERIAL_COUNT
	for i = 1, maxRecipeMaterialCount do
		local materialItem = recipeCls["Item_" .. i .. "_1"]
		if materialItem ~= nil and materialItem ~= "None" then
			local itemCls = GetClass("Item", materialItem)
			materialList = materialList .. itemCls.ClassID .. "#"
			local materialCnt = recipeCls["Item_" .. i .. "_1_Cnt"]
		end
end

	market.ReqRecipeSearchList(0, materialList)
end


function MARKET_DRAW_CTRLSET_RECIPE_SEARCHLIST_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "recipeSearchGbox");
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetRecipeSearchItemCount();

	DESTROY_CHILD_BYNAME(itemlist, "ITEM_MATERIAL_")

	local yPos = 0
	local index = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetRecipeSearchByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	
		
		local ctrlSet = itemlist:CreateControlSet("market_item_detail_default", "ITEM_MATERIAL_" .. index, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)

		ctrlSet:SetUserValue("marketRecipeSearchGuid", marketItem:GetMarketGuid())
		ctrlSet:SetUserValue("DETAIL_ROW", index);
		index = index + 1
		frame:SetUserValue("searchListIndex", index)

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local count = ctrlSet:GetChild("count");
		count:SetTextByKey("value", marketItem.count);
		
		local level = ctrlSet:GetChild("level");
		level:SetTextByKey("value", itemObj.UseLv);

		local price_num = ctrlSet:GetChild("price_num");
		price_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
		price_num:SetUserValue("Price", marketItem.sellPrice);

		local price_text = ctrlSet:GetChild("price_text");
		price_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));

		local reportBtn = ctrlSet:GetChild("reportBtn")
		reportBtn:ShowWindow(0)

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(0)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local editCount = GET_CHILD_RECURSIVELY(ctrlSet, "count")
			editCount:SetMinNumber(1)
			editCount:SetMaxNumber(marketItem.count)
			editCount:SetText("1")
			editCount:SetNumChangeScp("MARKET_CHANGE_COUNT");
			ctrlSet:SetUserValue("minItemCount", 1)
			ctrlSet:SetUserValue("maxItemCount", marketItem.count)
			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, true, false);

	local maxPage_recipe = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage_recipe = session.market.GetCurPage();
	local pagecontrol_recipe = GET_CHILD(frame, 'pagecontrol_recipe', 'ui::CPageController')
    if maxPage_recipe < 1 then
        maxPage_recipe = 1;
    end

	pagecontrol_recipe:SetMaxPage(maxPage_recipe);
	pagecontrol_recipe:SetCurPage(curPage_recipe);


	local maxPage_material = math.ceil(session.market.GetRecipeSearchCount() / RECIPE_SEARCH_COUNT_PER_PAGE);
	local curPage_material = session.market.GetRecipeSearchPage();

	local pagecontrol_material = GET_CHILD(frame, 'pagecontrol_material', 'ui::CPageController')
	pagecontrol_material:ShowWindow(1)
    if maxPage_material < 1 then
        maxPage_material = 1;
    end

	pagecontrol_material:SetMaxPage(maxPage_material);
	pagecontrol_material:SetCurPage(curPage_material);

end




function MARKET_DRAW_CTRLSET_ACCESSORY_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "accessoryTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_accessory", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local enchantOption = ""
		local strInfo = ""
		for j = 1 , 3 do
			local propName = "HatPropName_"..j;
			local propValue = "HatPropValue_"..j;
			if itemObj[propValue] ~= 0 and itemObj[propName] ~= "None" then
				enchantOption = ScpArgMsg(itemObj[propName]);
				if j == 1 then
					strInfo = strInfo .. ABILITY_DESC_PLUS(enchantOption, itemObj[propValue]);
				else
					strInfo = strInfo .. "{nl} " .. ABILITY_DESC_PLUS(enchantOption, itemObj[propValue]);
				end
			end
		end

		local enchantText = GET_CHILD_RECURSIVELY(ctrlSet, "enchant")
		enchantText:SetTextByKey("value", strInfo)

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end



function MARKET_DRAW_CTRLSET_GEM_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "gemTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_gem", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local gemLevel = GET_CHILD_RECURSIVELY(ctrlSet, "gemLevel")
		local gemLevelValue = GET_ITEM_LEVEL_EXP(itemObj)
		gemLevel:SetTextByKey("value", gemLevelValue)

		local gemRoastingLevel = TryGetProp(itemObj, 'GemRoastingLv', 0);
		local roastingLevel = GET_CHILD_RECURSIVELY(ctrlSet, "roastingLevel")
		roastingLevel:SetTextByKey("value", gemRoastingLevel)

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end


function MARKET_DRAW_CTRLSET_CARD_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "cardTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_card", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));

		local level = GET_CHILD_RECURSIVELY(ctrlSet, "level")
		level:SetTextByKey("value", itemObj.Level)

		local option = GET_CHILD_RECURSIVELY(ctrlSet, "option")

		local tempText1 = itemObj.Desc;
		if itemObj.Desc == "None" then
			tempText1 = "";
		end

		local textDesc = string.format("%s", tempText1)	
		option:SetTextByKey("value", textDesc);

		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end


function MARKET_DRAW_CTRLSET_EXPORB_SELLER_HOOKED(frame)
	local itemlist = GET_CHILD_RECURSIVELY(frame, "itemListGbox");
	itemlist:RemoveAllChild();
	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local count = session.market.GetItemCount();

	MARKET_SELECT_SHOW_TITLE(frame, "exporbTitle")

	local yPos = 0
	for i = 0 , count - 1 do
		local marketItem = session.market.GetItemByIndex(i);
		local itemObj = GetIES(marketItem:GetObject());
		local refreshScp = itemObj.RefreshScp;
		if refreshScp ~= "None" then
			refreshScp = _G[refreshScp];
			refreshScp(itemObj);
		end	

		local ctrlSet = itemlist:CreateControlSet("market_item_detail_exporb", "ITEM_EQUIP_" .. i, ui.LEFT, ui.TOP, 0, 0, 0, yPos);
		AUTO_CAST(ctrlSet)
		ctrlSet:SetUserValue("DETAIL_ROW", i);

		MARKET_CTRLSET_SET_ICON(ctrlSet, itemObj, marketItem);

		local name = ctrlSet:GetChild("name");
		name:SetTextByKey("value", GET_FULL_NAME(itemObj));


		local curExp, maxExp = GET_LEGENDEXPPOTION_EXP(itemObj)
		local expPoint = 0
		if maxExp ~= nil and maxExp ~= 0 then
			expPoint = curExp / maxExp * 100
		else 
			expPoint = 0
		end
		local expStr = string.format("%.2f", expPoint)

		MARKET_SET_EXPORB_ICON(ctrlSet, curExp, maxExp, itemObj)


		local exp = GET_CHILD_RECURSIVELY(ctrlSet, "exp")
		exp:SetTextByKey("value", expStr .. "%")


		if marketItem ~= nil then
			if _G["MARKETNAMES"] ~= nil then
				local marketName = _G["MARKETNAMES"][marketItem:GetSellerCID()];

				if marketName ~= nil then
					local buyButton = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");

					if buyButton ~= nil then
						buyButton:SetTextTooltip("Buy from " .. marketName.characterName .. " " .. marketName.familyName .. "!");
					end
				end
			end
		end

		if cid == marketItem:GetSellerCID() then
			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(0)
			buyBtn:SetEnable(0);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(1)
			cancelBtn:SetEnable(1)

			if USE_MARKET_REPORT == 1 then
				local reportBtn = ctrlSet:GetChild("reportBtn");
				reportBtn:SetEnable(0);
			end

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", 0);
			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", 0);
		else

			local buyBtn = GET_CHILD_RECURSIVELY(ctrlSet, "buyBtn");
			buyBtn:ShowWindow(1)
			buyBtn:SetEnable(1);
			local cancelBtn = GET_CHILD_RECURSIVELY(ctrlSet, "cancelBtn");
			cancelBtn:ShowWindow(0)
			cancelBtn:SetEnable(0)

			local totalPrice_num = ctrlSet:GetChild("totalPrice_num");
			totalPrice_num:SetTextByKey("value", GetCommaedText(marketItem.sellPrice));
			totalPrice_num:SetUserValue("Price", marketItem.sellPrice);

			local totalPrice_text = ctrlSet:GetChild("totalPrice_text");
			totalPrice_text:SetTextByKey("value", GetMonetaryString(marketItem.sellPrice));
			
		end		

		ctrlSet:SetUserValue("sellPrice", marketItem.sellPrice)
	end

	GBOX_AUTO_ALIGN(itemlist, 4, 0, 0, false, true);

	local maxPage = math.ceil(session.market.GetTotalCount() / MARKET_ITEM_PER_PAGE);
	local curPage = session.market.GetCurPage();
	local pagecontrol = GET_CHILD(frame, 'pagecontrol', 'ui::CPageController')
    if maxPage < 1 then
        maxPage = 1;
    end

	pagecontrol:SetMaxPage(maxPage);
	pagecontrol:SetCurPage(curPage);
end
