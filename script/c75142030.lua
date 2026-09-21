-- Phantom Knights's Xyz Dragon
local s,id=GetID()

function s.initial_effect(c)
	-- Xyz Summon Procedure
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.xyzcon)
	e1:SetTarget(s.xyztg)
	e1:SetOperation(s.xyzop)
	e1:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e1)
	
	-- Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.effcon)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

function s.mat1(c,xyzc,tp)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_MONSTER) and c:IsLevel(4)
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.IsExistingMatchingCard(s.mat1_sub,tp,LOCATION_MZONE,0,1,c,xyzc,tp,c)
end
function s.mat1_sub(c,xyzc,tp,c1)
	local g=Group.FromCards(c,c1)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_MONSTER) and c:IsLevel(4)
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.GetLocationCountFromEx(tp,tp,g,xyzc)>0
end
function s.mat2(c,xyzc,tp)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_XYZ) and c:GetRank()<=3
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.GetLocationCountFromEx(tp,tp,c,xyzc)>0
end
function s.xyzcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.mat1,tp,LOCATION_MZONE,0,1,nil,c,tp)
		or Duel.IsExistingMatchingCard(s.mat2,tp,LOCATION_MZONE,0,1,nil,c,tp)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local b1=Duel.IsExistingMatchingCard(s.mat1,tp,LOCATION_MZONE,0,1,nil,c,tp)
	local b2=Duel.IsExistingMatchingCard(s.mat2,tp,LOCATION_MZONE,0,1,nil,c,tp)
	local g=Group.CreateGroup()
	if b1 and b2 then
		local op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
		if op==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g1=Duel.SelectMatchingCard(tp,s.mat1,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
			g:Merge(g1)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g2=Duel.SelectMatchingCard(tp,s.mat1_sub,tp,LOCATION_MZONE,0,1,1,g1:GetFirst(),c,tp,g1:GetFirst())
			g:Merge(g2)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g1=Duel.SelectMatchingCard(tp,s.mat2,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
			g:Merge(g1)
		end
	elseif b1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g1=Duel.SelectMatchingCard(tp,s.mat1,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
		g:Merge(g1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g2=Duel.SelectMatchingCard(tp,s.mat1_sub,tp,LOCATION_MZONE,0,1,1,g1:GetFirst(),c,tp,g1:GetFirst())
		g:Merge(g2)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g1=Duel.SelectMatchingCard(tp,s.mat2,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
		g:Merge(g1)
	end
	if g and #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	local sg=Group.CreateGroup()
	for tc in aux.Next(g) do
		local mg=tc:GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(c,mg)
		end
	end
	c:SetMaterial(g)
	Duel.Overlay(c,g)
	g:DeleteGroup()
end

function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.cfilter(c)
	return c:IsSetCard(0xdb) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost() and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xdb) and c:IsType(TYPE_XYZ) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		if e:GetLabel()==2 then
			return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup()
		end
		return false
	end
	local b1=Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local pk_count=Duel.GetMatchingGroupCount(Auxiliary.FaceupFilter(Card.IsSetCard,0xdb),tp,LOCATION_MZONE,0,nil)
	local b2=pk_count>0 and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	
	if chk==0 then return b1 or b2 end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,5))+1
	end
	e:SetLabel(op+1)
	
	if op==0 then
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e:SetProperty(EFFECT_FLAG_DELAY)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
		Duel.SendtoGrave(g,REASON_COST)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	else
		e:SetCategory(CATEGORY_ATKCHANGE)
		e:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,pk_count,nil)
	end
end
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==1 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return end
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
		if ft>2 then ft=2 end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,ft,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	else
		local g=Duel.GetTargetCards(e)
		for tc in aux.Next(g) do
			if tc:IsFaceup() and tc:IsRelateToEffect(e) then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_SET_ATK_FINAL)
				e1:SetValue(math.ceil(tc:GetAtk()/2))
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end
