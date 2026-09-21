local s,id=GetID()
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e0)
	
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_FZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsOnField() and chkc:IsControler(tp) and chkc~=c end
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=4
		and Duel.IsExistingTarget(nil,tp,LOCATION_ONFIELD,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,nil,tp,LOCATION_ONFIELD,0,1,1,c)
end

function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ)
end

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<4 then return end
	Duel.ConfirmDecktop(tp,4)
	local g=Duel.GetDecktopGroup(tp,4)
	local sg=g:Filter(Card.IsSetCard,nil,0x115)
	if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
		local tc=sg:Select(tp,1,1,nil):GetFirst()
		if tc then
			g:RemoveCard(tc)
			local b1=tc:IsAbleToHand()
			local xyz_g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil)
			local b2=#xyz_g>0
			
			local op=0
			if b1 and b2 then
				op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
			elseif b1 then
				op=0
			elseif b2 then
				op=1
			else
				op=2
			end
			
			if op==0 then
				Duel.DisableShuffleCheck()
				Duel.SendtoHand(tc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,tc)
				Duel.ShuffleHand(tp)
			elseif op==1 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
				local xyz_c=xyz_g:Select(tp,1,1,nil):GetFirst()
				if xyz_c then
					Duel.DisableShuffleCheck()
					Duel.Overlay(xyz_c,tc)
				end
			end
		end
	end
	Duel.ShuffleDeck(tp)
end