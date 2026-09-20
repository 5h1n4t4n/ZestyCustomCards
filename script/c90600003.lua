-- Sky Striker Ace - The Fallen Automaton
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	if Link and Link.AddProcedure then
		Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),2,2)
	else
		aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x115),2,2)
	end
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.negcon1)
	e1:SetTarget(s.negtg1)
	e1:SetOperation(s.negop1)
	c:RegisterEffect(e1)

	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.adjustop)
	c:RegisterEffect(e2)
	
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetCountLimit(2)
	e3:SetCondition(s.discon)
	e3:SetCost(s.discost)
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
	
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_REMOVE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.thcon)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

if not s.sky_striker_hooked then
	s.sky_striker_hooked=true
	
	local old_GetFieldGroupCount=Duel.GetFieldGroupCount
	local old_GetFieldGroup=Duel.GetFieldGroup
	local old_GetMatchingGroupCount=Duel.GetMatchingGroupCount
	local old_IsExistingMatchingCard=Duel.IsExistingMatchingCard

	local function is_fallen_active(tp)
		return old_IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsCode(id) end, tp, LOCATION_MZONE, 0, 1, nil)
	end

	local function is_mmzone(loc)
		if not loc then return false end
		local mmz = rawget(_G, "LOCATION_MMZONE")
		return (mmz and loc == mmz)
	end

	if old_GetFieldGroupCount then
		Duel.GetFieldGroupCount=function(p, s_loc, o_loc, ...)
			if is_mmzone(s_loc) and is_fallen_active(p) then
				return 0
			end
			return old_GetFieldGroupCount(p, s_loc, o_loc, ...)
		end
	end

	if old_GetFieldGroup then
		Duel.GetFieldGroup=function(p, s_loc, o_loc, ...)
			if is_mmzone(s_loc) and is_fallen_active(p) then
				return Group.CreateGroup()
			end
			return old_GetFieldGroup(p, s_loc, o_loc, ...)
		end
	end

	if old_GetMatchingGroupCount then
		Duel.GetMatchingGroupCount=function(f, p, s_loc, o_loc, ex, ...)
			if is_mmzone(s_loc) and is_fallen_active(p) then
				return 0
			end
			return old_GetMatchingGroupCount(f, p, s_loc, o_loc, ex, ...)
		end
	end

	if old_IsExistingMatchingCard then
		Duel.IsExistingMatchingCard=function(f, p, s_loc, o_loc, ct, ex, ...)
			if is_mmzone(s_loc) and is_fallen_active(p) then
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
					if Duel.IsExistingMatchingCard(function(tc) return tc:IsFaceup() and tc:IsCode(id) end,c:GetControler(),LOCATION_MZONE,0,1,nil) then
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

function s.negcon1(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.negtg1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() and chkc:IsFaceup() and not chkc:IsDisabled() end
	if chk==0 then return Duel.IsExistingTarget(function(c) return c:IsFaceup() and not c:IsDisabled() end,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectTarget(tp,function(c) return c:IsFaceup() and not c:IsDisabled() end,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end
function s.negop1(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end

function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end
function s.costfilter(c)
	return c:IsSetCard(0x115) and c:IsAbleToGraveAsCost()
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateEffect(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEDOWN,REASON_EFFECT)
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return re and re:GetHandler()==e:GetHandler()
end
function s.thfilter(c,eg)
	return c:IsSetCard(0x115) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToHand()
		and not eg:IsExists(Card.IsCode,1,nil,c:GetCode())
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,eg) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(function(c) return s.thfilter(c,eg) end),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end