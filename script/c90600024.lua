-- Sky Striker Airspace - Sector Omega
local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt Field Spell
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)

	-- Hiệu ứng 1: Đào 4 lá trên cùng Bộ bài (Excavate)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-- Hiệu ứng 2: Cho phép kích hoạt Sky Striker Spell kể cả khi có quái thú ở Main Monster Zone
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ADJUST)
	e3:SetRange(LOCATION_FZONE)
	e3:SetOperation(s.adjustop)
	c:RegisterEffect(e3)

	-- Hiệu ứng 3: Tăng công thủ (100 ATK/DEF cho mỗi Spell trong Mộ)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetTarget(s.atktg)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e5)
end
s.listed_series={0x115} -- Setcode Sky Striker

-- ==================================================
-- HỆ THỐNG HOOK: Override lỗi Main Monster Zone
-- ==================================================
if not s.sky_striker_hooked then
	s.sky_striker_hooked=true
	
	local old_GetFieldGroupCount=Duel.GetFieldGroupCount
	local old_GetFieldGroup=Duel.GetFieldGroup
	local old_GetMatchingGroupCount=Duel.GetMatchingGroupCount
	local old_IsExistingMatchingCard=Duel.IsExistingMatchingCard

	local function is_omega_active(tp)
		return old_IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(id) and not c:IsDisabled() end, tp, LOCATION_FZONE, 0, 1, nil)
	end

	local function is_mmzone(loc)
		if not loc then return false end
		local mmz = rawget(_G, "LOCATION_MMZONE")
		return (mmz and loc == mmz)
	end

	if old_GetFieldGroupCount then
		Duel.GetFieldGroupCount=function(p, s_loc, o_loc, ...)
			if is_mmzone(s_loc) and is_omega_active(p) then
				return 0
			end
			return old_GetFieldGroupCount(p, s_loc, o_loc, ...)
		end
	end

	if old_GetFieldGroup then
		Duel.GetFieldGroup=function(p, s_loc, o_loc, ...)
			if is_mmzone(s_loc) and is_omega_active(p) then
				return Group.CreateGroup()
			end
			return old_GetFieldGroup(p, s_loc, o_loc, ...)
		end
	end

	if old_GetMatchingGroupCount then
		Duel.GetMatchingGroupCount=function(f, p, s_loc, o_loc, ex, ...)
			if is_mmzone(s_loc) and is_omega_active(p) then
				return 0
			end
			return old_GetMatchingGroupCount(f, p, s_loc, o_loc, ex, ...)
		end
	end

	if old_IsExistingMatchingCard then
		Duel.IsExistingMatchingCard=function(f, p, s_loc, o_loc, ct, ex, ...)
			if is_mmzone(s_loc) and is_omega_active(p) then
				return false
			end
			return old_IsExistingMatchingCard(f, p, s_loc, o_loc, ct, ex, ...)
		end
	end
end

s.patched_tables = {}
function s.patch_cfilter()
	for k,v in pairs(_G) do
		if type(k)=="string" and k:sub(1,1)=="c" and type(v)=="table" and not s.patched_tables[v] then
			if type(v.cfilter)=="function" then
				local old_cfilter=v.cfilter
				v.cfilter=function(c,...)
					if Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and tc:IsCode(id) and not tc:IsDisabled() end,c:GetControler(),LOCATION_FZONE,0,1,nil) then
						return false
					end
					return old_cfilter(c,...)
				end
				s.patched_tables[v]=true
			end
		end
	end
end
s.patch_cfilter()

function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
	s.patch_cfilter()
end

-- ==================================================
-- HIỆU ỨNG 1: Đào bài (Excavate)
-- ==================================================
function s.tgtcfilter(c)
	return c:IsFaceup()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsOnField() and s.tgtcfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4 
		and Duel.IsExistingTarget(s.tgtcfilter,tp,LOCATION_ONFIELD,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgtcfilter,tp,LOCATION_ONFIELD,0,1,1,e:GetHandler())
	-- Đã thêm SetOperationInfo để core game nhận chuẩn hiệu ứng TOHAND
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK) 
end

function s.excfilter(c,xyz_check)
	return c:IsSetCard(0x115) and (c:IsAbleToHand() or xyz_check)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<4 then return end
	
	Duel.ConfirmDecktop(tp,4)
	local g=Duel.GetDecktopGroup(tp,4)
	if #g==0 then return end
	
	-- QUAN TRỌNG NHẤT LÀ DÒNG NÀY: Khóa xáo bài ngay lập tức để game không bị mất dấu lá bài
	Duel.DisableShuffleCheck()
	
	local xyzg=Duel.GetMatchingGroup(function(c) return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x115) end,tp,LOCATION_MZONE,0,nil)
	local xyz_check = #xyzg > 0
	
	local sg=g:Filter(s.excfilter,nil,xyz_check)
	if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
		
		-- Ép lá bài được chọn thành đối tượng Group để xử lý không bao giờ lỗi
		local tg=sg:Select(tp,1,1,nil)
		local sc=tg:GetFirst()
		
		local b1 = sc:IsAbleToHand()
		local b2 = xyz_check
		
		local op=0
		-- Nếu có Xyz trên sân, hiện tùy chọn Add hoặc Attach
		if b1 and b2 then
			op=Duel.SelectOption(tp,1190,aux.Stringid(id,2)) -- 1190: Add to hand
		-- Nếu không có Xyz, tự động gán op = 0 (Chỉ Add to hand)
		elseif b1 then
			op=0
		else
			op=1
		end
		
		if op==0 then
			-- SendtoHand dùng 'tg' (Group) thay vì 'sc' (Single Card)
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tg)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
			local xyz_tc=xyzg:Select(tp,1,1,nil):GetFirst()
			if xyz_tc then
				Duel.Overlay(xyz_tc,tg)
			end
		end
	end
	Duel.ShuffleDeck(tp)
end

-- ==================================================
-- HIỆU ỨNG 3: Tăng ATK/DEF
-- ==================================================
function s.atktg(e,c)
	return c:IsSetCard(0x115)
end
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(Card.IsType,c:GetControler(),LOCATION_GRAVE,0,nil,TYPE_SPELL)*100
end