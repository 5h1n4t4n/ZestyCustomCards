-- Dan Heng Permansor Terrae - Demigod of Earth
-- ID: 888800006
local s,id=GetID()

local SET_CHRYSOS_HEIRS = 0xffa
local CARD_ERA_NOVA  = 888800001

s.listed_series={SET_CHRYSOS_HEIRS}
s.listed_names={CARD_ERA_NOVA}

function s.initial_effect(c)
	-- Pendulum Summon & Ritual Procedure
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c)

	-- Quy tắc: Luôn được coi là lá "Chrysos Heirs"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SET_CHRYSOS_HEIRS)
	c:RegisterEffect(e0)

	----------------------------------------------------------------------------
	-- PENDULUM EFFECTS
	----------------------------------------------------------------------------
	-- P-Eff 1: Không thể Pendulum Summon
	local pe1=Effect.CreateEffect(c)
	pe1:SetType(EFFECT_TYPE_FIELD)
	pe1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	pe1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	pe1:SetRange(LOCATION_PZONE)
	pe1:SetTargetRange(1,0)
	pe1:SetTarget(s.pendlimit)
	c:RegisterEffect(pe1)

	-- P-Eff 2: Bảo vệ quái "Chrysos Heirs" khỏi bị phá hủy lần đầu tiên mỗi lượt
	local pe2=Effect.CreateEffect(c)
	pe2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	pe2:SetCode(EFFECT_DESTROY_SUBSTITUTE)
	pe2:SetRange(LOCATION_PZONE)
	pe2:SetTargetRange(LOCATION_MZONE,0)
	pe2:SetTarget(s.reptg)
	pe2:SetValue(s.repval)
	pe2:SetOperation(s.repop)
	c:RegisterEffect(pe2)

	-- P-Eff 3: Quick Effect hủy lá này để negate hiệu ứng quái đối thủ & hồi 1500 LP (1 lần/lượt)
	local pe3=Effect.CreateEffect(c)
	pe3:SetDescription(aux.Stringid(id,0))
	pe3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_RECOVER)
	pe3:SetType(EFFECT_TYPE_QUICK_O)
	pe3:SetCode(EVENT_CHAINING)
	pe3:SetRange(LOCATION_PZONE)
	pe3:SetCountLimit(1,id)
	pe3:SetCondition(s.discon)
	pe3:SetCost(s.discost)
	pe3:SetTarget(s.distg)
	pe3:SetOperation(s.disop)
	c:RegisterEffect(pe3)

	----------------------------------------------------------------------------
	-- MONSTER EFFECTS
	----------------------------------------------------------------------------
	-- M-Eff 1: Tự SS từ Extra Deck khi "Chrysos Heirs" được SS (1 lần/lượt)
	local me1=Effect.CreateEffect(c)
	me1:SetDescription(aux.Stringid(id,1))
	me1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	me1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	me1:SetProperty(EFFECT_FLAG_DELAY)
	me1:SetCode(EVENT_SPSUMMON_SUCCESS)
	me1:SetRange(LOCATION_EXTRA)
	me1:SetCountLimit(1,id+100)
	me1:SetCondition(s.exspcon)
	me1:SetTarget(s.exsptg)
	me1:SetOperation(s.exspop)
	c:RegisterEffect(me1)

	-- M-Eff 2: Khi bị hiến tế (Tributed): Gọi 1 quái "Chrysos Heirs" từ GY/Banish/Extra (1 lần/lượt)
	local me2=Effect.CreateEffect(c)
	me2:SetDescription(aux.Stringid(id,2))
	me2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	me2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	me2:SetProperty(EFFECT_FLAG_DELAY)
	me2:SetCode(EVENT_RELEASE)
	me2:SetCountLimit(1,id+200)
	me2:SetTarget(s.sptg)
	me2:SetOperation(s.spop)
	c:RegisterEffect(me2)
end

--------------------------------------------------------------------------------
-- PENDULUM LOGIC
--------------------------------------------------------------------------------
function s.pendlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

function s.repfilter(c,tp)
	return c:IsControler(tp) and c:IsFaceup() and c:IsSetCard(SET_CHRYSOS_HEIRS)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp) and c:GetFlagEffect(id)==0 end
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
	return true
end

function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
end

function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsRelateToEffect(e) end
	Duel.Destroy(c,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1500)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		if Duel.Destroy(eg,REASON_EFFECT)>0 then
			Duel.BreakEffect()
			Duel.Recover(tp,1500,REASON_EFFECT)
		end
	end
end

--------------------------------------------------------------------------------
-- MONSTER LOGIC
--------------------------------------------------------------------------------
function s.exspcfilter(c,tp)
	return c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsControler(tp) and c:IsFaceup()
end

function s.exspcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsFaceup() and eg:IsExists(s.exspcfilter,1,nil,tp)
end

function s.exsptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- Sửa tham số true để lách Revive Limit khi SS từ Extra Deck
	if chk==0 then return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,true) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.exspop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		-- Sửa tham số true
		Duel.SpecialSummon(c,0,tp,tp,false,true,POS_FACEUP)
	end
end

function s.spfilter(c,e,tp)
	if not (c:IsSetCard(SET_CHRYSOS_HEIRS) and c:IsType(TYPE_MONSTER) and not c:IsCode(id)) then return false end
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,true) then return false end
	if c:IsLocation(LOCATION_GRAVE) then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	elseif c:IsLocation(LOCATION_REMOVED) then
		return c:IsFaceup() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	elseif c:IsLocation(LOCATION_EXTRA) then
		return c:IsFaceup() and c:IsType(TYPE_PENDULUM) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
	end
	return false
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,true,POS_FACEUP)
	end
end