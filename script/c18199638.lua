-- Dehya - Genshin the member of Eremites
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,s.xyzmfilter,8,2,nil,nil,Xyz.InfiniteMats)
	-- Alt Xyz
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetTarget(s.xyztg)
	e0:SetOperation(s.xyzop2)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)
	-- Attach Deck top
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.mttg)
	e1:SetOperation(s.mtop)
	c:RegisterEffect(e1)
	-- Quick Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetTarget(s.eftg)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
end
s.listed_series={0x369}
function s.xyzmfilter(c)
	return c:IsSetCard(0x369)
end
function s.xyzfilter(c)
	return c:IsSetCard(0x369) and c:IsAbleToGraveAsCost()
end
function s.matfilter2(c,sc)
	return c:IsFaceup() and c:IsSetCard(0x369) and c:IsLevelAbove(6) and c:IsCanBeXyzMaterial(sc)
end
function s.xyzcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	return ft>-1 and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.IsExistingMatchingCard(s.matfilter2,tp,LOCATION_MZONE,0,1,nil,c)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
	local mg=Duel.GetMatchingGroup(s.matfilter2,tp,LOCATION_MZONE,0,nil,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_HAND,0,0,1,nil)
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g2=mg:Select(tp,1,1,nil)
		if #g2>0 then
			g1:KeepAlive()
			g2:KeepAlive()
			e:SetLabelObject({g1,g2})
			return true
		end
	end
	return false
end
function s.xyzop2(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	local tab=e:GetLabelObject()
	local g1=tab[1]
	local g2=tab[2]
	Duel.SendtoGrave(g1,REASON_COST)
	local tc=g2:GetFirst()
	local mg=tc:GetOverlayGroup()
	if #mg>0 then
		Duel.Overlay(c,mg)
	end
	c:SetMaterial(g2)
	Duel.Overlay(c,g2)
	g1:DeleteGroup()
	g2:DeleteGroup()
end
function s.mttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 end
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0 then
		local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
		Duel.DisableShuffleCheck()
		Duel.Overlay(c,tc)
	end
end
function s.tgtfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x369)
end
function s.eftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then
		if e:GetLabel()==1 then
			return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgtfilter(chkc)
		end
		return false
	end
	if chk==0 then
		local b1 = c:CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingTarget(s.tgtfilter,tp,LOCATION_MZONE,0,1,nil)
		local b2 = c:CheckRemoveOverlayCard(tp,2,REASON_COST) and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
		return b1 or b2
	end
	
	local b1 = c:CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingTarget(s.tgtfilter,tp,LOCATION_MZONE,0,1,nil)
	local b2 = c:CheckRemoveOverlayCard(tp,2,REASON_COST) and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))+1
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3))+1
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,4))+2
	end
	
	e:SetLabel(op)
	c:RemoveOverlayCard(tp,op,op,REASON_COST)
	
	if op==1 then
		e:SetCategory(0)
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		Duel.SelectTarget(tp,s.tgtfilter,tp,LOCATION_MZONE,0,1,1,nil)
	else
		e:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE+CATEGORY_DAMAGE)
		e:SetProperty(0)
	end
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local op=e:GetLabel()
	if op==1 then
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	elseif op==2 then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		for tc in aux.Next(g) do
			local preatk=tc:GetAttack()
			local predef=tc:GetDefense()
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(math.ceil(preatk/2))
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_SET_DEFENSE_FINAL)
			e2:SetValue(math.ceil(predef/2))
			tc:RegisterEffect(e2)
			
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
			e3:SetCode(EVENT_LEAVE_FIELD)
			e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
			e3:SetCondition(s.damcon)
			e3:SetOperation(s.damop)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
			tc:RegisterEffect(e3,true)
		end
	end
end
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) or c:IsReason(REASON_EFFECT) or c:IsReason(REASON_MATERIAL) or c:IsReason(REASON_COST) or c:IsReason(REASON_BATTLE)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local val=c:GetPreviousAttackOnField()
	if val>0 then
		Duel.Damage(c:GetPreviousControler(),val,REASON_EFFECT)
	end
	e:Reset()
end
