--Zombie Dai Grepher
local s,id=GetID()
function s.initial_effect(c)
	--Send to GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)
	--Change Level
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.lvtg)
	e3:SetOperation(s.lvop)
	c:RegisterEffect(e3)
end
function s.tgfilter(c)
	return c:IsRace(RACE_ZOMBIE) and c:IsAbleToGrave() and not c:IsCode(id)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.disfilter(c)
	return c:IsRace(RACE_ZOMBIE) and c:IsFaceup() and not c:IsDisabled()
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		local zw=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,4064256),tp,LOCATION_ONFIELD,0,1,nil)
		local dis_g=Duel.GetMatchingGroup(s.disfilter,tp,0,LOCATION_MZONE,nil)
		if zw and #dis_g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
			local sg=dis_g:Select(tp,1,1,nil)
			local tc=sg:GetFirst()
			if tc then
				Duel.HintSelection(sg)
				local c=e:GetHandler()
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_DISABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_DISABLE_EFFECT)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e2)
			end
		end
	end
end
function s.lvfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_ZOMBIE) and c:HasLevel()
end
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.lvfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=2
		and Duel.IsExistingTarget(s.lvfilter,tp,LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.lvfilter,tp,LOCATION_MZONE,0,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,2,tp,LOCATION_DECK)
end
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=2 then
		Duel.DiscardDeck(tp,2,REASON_EFFECT)
		local og=Duel.GetOperatedGroup()
		if #og>0 and og:FilterCount(Card.IsLocation,nil,LOCATION_GRAVE)>0 then
			if tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:HasLevel() then
				local b_dec1 = (tc:GetLevel() > 1)
				local b_dec2 = (tc:GetLevel() > 2)
				local ops={}
				local opval={}
				table.insert(ops,aux.Stringid(id,3))
				table.insert(opval,1)
				table.insert(ops,aux.Stringid(id,4))
				table.insert(opval,2)
				if b_dec1 then
					table.insert(ops,aux.Stringid(id,5))
					table.insert(opval,-1)
				end
				if b_dec2 then
					table.insert(ops,aux.Stringid(id,6))
					table.insert(opval,-2)
				end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
				local sel=Duel.SelectOption(tp,table.unpack(ops))+1
				local val=opval[sel]
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_LEVEL)
				e1:SetValue(val)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end
