--Flower Spirit - Ferral Spring
local s,id=GetID()
local COUNTER_FLOWER=0x702

function s.initial_effect(c)
	c:EnableReviveLimit()
	Pendulum.AddProcedure(c)
	
	--Cho phep nhan Flower Counter tai Pendulum Zone va Monster Zone
	c:EnableCounterPermit(COUNTER_FLOWER,LOCATION_PZONE+LOCATION_MZONE)
	
	--Special Summon Procedure: Shuffle 3 "Flower Spirit" Spells from GY/banish into Deck
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetTarget(s.sptg)
	e0:SetOperation(s.spop)
	e0:SetValue(SUMMON_TYPE_SPECIAL)
	c:RegisterEffect(e0)
	
	--Cannot be Special Summoned by card effects (except ignoring conditions)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.FALSE)
	c:RegisterEffect(e1)
	
	--Pendulum Effect: Place 1 Flower Counter each time a "Flower Spirit" Spell resolves
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetRange(LOCATION_PZONE)
	e2:SetOperation(s.ctop)
	c:RegisterEffect(e2)
	
	--Pendulum Effect: Remove 10 Flower Counters; draw 2 cards, then destroy this card
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_PZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.drawcost)
	e3:SetTarget(s.drawtg)
	e3:SetOperation(s.drawop)
	c:RegisterEffect(e3)
	
	--Monster Effect: If Special Summoned: Place as many FS Spells from GY as Normal Monsters
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.mztg)
	e4:SetOperation(s.mzop)
	c:RegisterEffect(e4)
	
	--Monster Effect: Once per turn: Place this card in your Pendulum Zone
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,2))
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+100)
	e5:SetTarget(s.pztg)
	e5:SetOperation(s.pzop)
	c:RegisterEffect(e5)

	--Global Check: Track Special Summon (You can only Special Summon "Flower Spirit - Ferral Spring" once per turn)
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
		ge1:SetOperation(s.checkop)
		Duel.RegisterEffect(ge1,0)
	end)
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	for tc in aux.Next(eg) do
		if tc:IsCode(id) then
			Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
		end
	end
end

--Procedure: Shuffle 3 "Flower Spirit" Spells from GY/banish into Deck
function s.spfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL) and c:IsAbleToDeckAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFlagEffect(tp,id)==0
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,3,3,nil)
	if #g==3 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
	g:DeleteGroup()
end

--Pendulum Counter Logic
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if re:IsActiveType(TYPE_SPELL) and re:GetHandler():IsSetCard(0x702) and re:GetHandlerPlayer()==tp then
		e:GetHandler():AddCounter(COUNTER_FLOWER,1)
	end
end
function s.drawcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanRemoveCounter(tp,COUNTER_FLOWER,10,REASON_COST) end
	e:GetHandler():RemoveCounter(tp,COUNTER_FLOWER,10,REASON_COST)
end
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.Draw(tp,2,REASON_EFFECT)==2 and c:IsRelateToEffect(e) then
		Duel.BreakEffect()
		Duel.Destroy(c,REASON_EFFECT)
	end
end

--Monster Effect: Move Spells from GY to Monster Zone as Normal Monsters (as many as possible)
function s.mzfilter(c)
	return c:IsSetCard(0x702) and c:IsType(TYPE_SPELL)
end
function s.mztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.mzfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
end
function s.mzop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	local g=Duel.GetMatchingGroup(s.mzfilter,tp,LOCATION_GRAVE,0,nil)
	if #g==0 then return end
	local max_count=math.min(ft,#g)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local sg=g:Select(tp,1,max_count,nil)
	local c=e:GetHandler()
	for tc in aux.Next(sg) do
		if Duel.MoveToField(tc,tp,tp,LOCATION_MZONE,POS_FACEUP,true) then
			--Add Monster and Normal types
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_ADD_TYPE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(TYPE_MONSTER+TYPE_NORMAL)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			--Set Level 4
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_CHANGE_LEVEL)
			e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e2:SetValue(4)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
			--Set Race Spellcaster
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_CHANGE_RACE)
			e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e3:SetValue(RACE_SPELLCASTER)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e3)
			--Set Attribute LIGHT
			local e4=Effect.CreateEffect(c)
			e4:SetType(EFFECT_TYPE_SINGLE)
			e4:SetCode(EFFECT_CHANGE_ATTRIBUTE)
			e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e4:SetValue(ATTRIBUTE_LIGHT)
			e4:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e4)
			--Set ATK 0
			local e5=Effect.CreateEffect(c)
			e5:SetType(EFFECT_TYPE_SINGLE)
			e5:SetCode(EFFECT_SET_BASE_ATTACK)
			e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e5:SetValue(0)
			e5:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e5)
			--Set DEF 0
			local e6=Effect.CreateEffect(c)
			e6:SetType(EFFECT_TYPE_SINGLE)
			e6:SetCode(EFFECT_SET_BASE_DEFENSE)
			e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e6:SetValue(0)
			e6:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e6)
		end
	end
end

--Move to Pendulum Zone
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckPendulumZones(tp) end
end
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.CheckPendulumZones(tp) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
