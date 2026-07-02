-- Alhaitham - Genshin the Member of Akademiya
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x369),8,2,nil,nil,Xyz.InfiniteMats)
	-- Alt Xyz
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetTarget(s.xyztg)
	e0:SetOperation(s.xyzop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)
	-- Attach
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.attcon)
	e1:SetTarget(s.atttg)
	e1:SetOperation(s.attop)
	c:RegisterEffect(e1)
	-- Quick Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCost(s.efcost)
	e2:SetTarget(s.eftg)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
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
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
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
function s.attcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
end
function s.attop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 then
		local g=Duel.GetDecktopGroup(tp,1)
		Duel.Overlay(c,g)
	end
end
function s.tgtfilter1(c)
	return c:IsFaceup() and c:IsSetCard(0x369)
end
function s.tgtfilter2(c)
	return c:IsSetCard(0x369) and c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
end
function s.efcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) and Duel.IsExistingTarget(s.tgtfilter1,tp,LOCATION_MZONE,0,1,nil)
	local b2=e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) and Duel.IsExistingTarget(s.tgtfilter2,tp,LOCATION_REMOVED,0,1,nil)
	if chk==0 then return b1 or b2 end
	local ops={}
	local opval={}
	if b1 then
		table.insert(ops,aux.Stringid(id,2))
		table.insert(opval,1)
	end
	if b2 then
		table.insert(ops,aux.Stringid(id,3))
		table.insert(opval,2)
	end
	local op=Duel.SelectOption(tp,table.unpack(ops))
	local sel=opval[op+1]
	e:GetHandler():RemoveOverlayCard(tp,sel,sel,REASON_COST)
	e:SetLabel(sel)
end
function s.eftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local ct=e:GetLabel()
	if chkc then
		if ct==1 then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgtfilter1(chkc) end
		if ct==2 then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.tgtfilter2(chkc) end
	end
	if chk==0 then return true end
	if ct==1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		Duel.SelectTarget(tp,s.tgtfilter1,tp,LOCATION_MZONE,0,1,1,nil)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectTarget(tp,s.tgtfilter2,tp,LOCATION_REMOVED,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	end
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local ct=e:GetLabel()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if ct==1 then
		if tc:IsFaceup() then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_IMMUNE_EFFECT)
			e1:SetValue(s.immval)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	else
		if Duel.SendtoDeck(tc,nil,2,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
			local atk=tc:GetBaseAttack()
			local def=tc:GetBaseDefense()
			if atk<0 then atk=0 end
			if def<0 then def=0 end
			local c=e:GetHandler()
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(atk)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
				c:RegisterEffect(e1)
				local e2=e1:Clone()
				e2:SetCode(EFFECT_UPDATE_DEFENSE)
				e2:SetValue(def)
				c:RegisterEffect(e2)
			end
		end
	end
end
function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActiveType(TYPE_MONSTER)
end
