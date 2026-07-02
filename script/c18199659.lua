-- Genshin Superpower - Ultimate Sacrifice
local s,id=GetID()
function s.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x369}
function s.costfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x369) and c:IsSummonLocation(LOCATION_EXTRA)
		and (c:IsType(TYPE_FUSION) or c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_XYZ) or c:IsType(TYPE_LINK))
		and c:IsReleasable()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.Release(g,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CARDTYPE)
	local opt=Duel.SelectOption(tp,70,71,72)
	local ctype=TYPE_MONSTER
	if opt==1 then ctype=TYPE_SPELL elseif opt==2 then ctype=TYPE_TRAP end
	e:SetLabel(ctype)
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(aux.FALSE)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ctype=e:GetLabel()
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_HAND+LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.ConfirmCards(tp,g)
		local rg=g:Filter(Card.IsType,nil,ctype)
		if #rg>0 then
			Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
		end
		Duel.ShuffleHand(1-tp)
	end
	-- Look at drawn cards and banish until end of next turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_DRAW)
	e1:SetOperation(s.drawop)
	e1:SetLabel(ctype)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	Duel.RegisterEffect(e1,tp)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	if ep==1-tp then
		Duel.ConfirmCards(tp,eg)
		local rg=eg:Filter(Card.IsType,nil,e:GetLabel())
		if #rg>0 then
			Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
		end
		Duel.ShuffleHand(1-tp)
	end
end
