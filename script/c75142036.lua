-- Elegant Harpie Lady Sisters
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Procedure: 3 WIND monsters
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,3)
	
	-- Only control 1
	c:SetUniqueOnField(1,0,id)
	
	-- Global check for Special Summon count this turn
	if not s.global_check then
		s.global_check=true
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end
	
	-- Special Summon 1 "Harpie" from Deck or GY
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	
	-- Unaffected if summoned using only field monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.immcon)
	e2:SetOperation(s.immop)
	c:RegisterEffect(e2)
	
	-- 1+: Gain 1000 ATK/DEF
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetCondition(function(e) return Duel.GetFlagEffect(0,id)>=1 end)
	e3:SetValue(1000)
	c:RegisterEffect(e3)
	local e3b=e3:Clone()
	e3b:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3b)
	
	-- 3+: Neither player can add card from Deck except Harpie / Hysteric
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_CANNOT_TO_HAND)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_DECK,LOCATION_DECK)
	e4:SetCondition(function(e) return Duel.GetFlagEffect(0,id)>=3 end)
	e4:SetTarget(s.thlimit)
	c:RegisterEffect(e4)
	
	-- 5+: Neither player can Special Summon from hand or Deck
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e5:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(1,1)
	e5:SetCondition(function(e) return Duel.GetFlagEffect(0,id)>=5 end)
	e5:SetTarget(s.sumlimit)
	c:RegisterEffect(e5)
	
	-- 7+: Neither player can activate Spell/Trap except Harpie / Hysteric
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e6:SetCode(EFFECT_CANNOT_ACTIVATE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetTargetRange(1,1)
	e6:SetCondition(function(e) return Duel.GetFlagEffect(0,id)>=7 end)
	e6:SetValue(s.aclimit)
	c:RegisterEffect(e6)
end

function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_WIND)
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for i=1,#eg do
		Duel.RegisterFlagEffect(0,id,RESET_PHASE+PHASE_END,0,1)
	end
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x64) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

function s.immcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=c:GetMaterial()
	return c:IsSummonType(SUMMON_TYPE_FUSION) and #mg>0 
		and not mg:IsExists(aux.NOT(Card.IsPreviousLocation),1,nil,LOCATION_ONFIELD)
end
function s.immop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end
function s.efilter(e,te)
	return te:GetOwner()~=e:GetHandler()
end

function s.thlimit(e,c)
	return not (c:IsSetCard(0x64) or c:IsSetCard(0x2076) or c:IsCode(77778835,56840658,75142032,75142033,75142034,75142035))
end

function s.sumlimit(e,c,sump,sumtype,sumpos,target_p)
	return c:IsLocation(LOCATION_HAND+LOCATION_DECK)
end

function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_SPELL+TYPE_TRAP) 
		and not (rc:IsSetCard(0x64) or rc:IsSetCard(0x2076) or rc:IsCode(77778835,56840658,75142032,75142035))
end
