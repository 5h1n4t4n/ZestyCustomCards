-- The Phantom Knights's King
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz Summon
	c:EnableReviveLimit()
	-- Custom Xyz Summon procedure
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
	
	-- Rank 5 (always treated as Rank 5)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CHANGE_RANK)
	e1:SetValue(5)
	c:RegisterEffect(e1)
	
	-- Unique
	c:SetUniqueOnField(1,0,id)
	
	-- Target Immunity
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.tgtg)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
	
	-- Shuffle and Set
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_TODECK)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e4:SetCountLimit(1)
	e4:SetTarget(s.tdtg)
	e4:SetOperation(s.tdop)
	c:RegisterEffect(e4)
	
	-- Destroy
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.descon)
	e5:SetCost(s.descost)
	e5:SetTarget(s.destg)
	e5:SetOperation(s.desop)
	c:RegisterEffect(e5)
end

function s.mat1(c,xyzc,tp)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_MONSTER) and c:HasLevel()
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.IsExistingMatchingCard(s.mat1_sub,tp,LOCATION_MZONE,0,1,c,c:GetLevel(),xyzc,tp,c)
end
function s.mat1_sub(c,lvl,xyzc,tp,c1)
	local g=Group.FromCards(c,c1)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_MONSTER) and c:IsLevel(lvl)
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.GetLocationCountFromEx(tp,tp,g,xyzc)>0
end
function s.mat2(c,xyzc,tp)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_XYZ) and c:GetRank()>0
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.IsExistingMatchingCard(s.mat2_sub,tp,LOCATION_MZONE,0,1,c,c:GetRank(),xyzc,tp,c)
end
function s.mat2_sub(c,rnk,xyzc,tp,c1)
	local g=Group.FromCards(c,c1)
	return c:IsFaceup() and c:IsSetCard(0xdb) and c:IsType(TYPE_XYZ) and c:GetRank()==rnk
		and c:IsCanBeXyzMaterial(xyzc,tp)
		and Duel.GetLocationCountFromEx(tp,tp,g,xyzc)>0
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
			local tc1=g1:GetFirst()
			g:Merge(g1)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g2=Duel.SelectMatchingCard(tp,s.mat1_sub,tp,LOCATION_MZONE,0,1,1,tc1,tc1:GetLevel(),c,tp,tc1)
			g:Merge(g2)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g1=Duel.SelectMatchingCard(tp,s.mat2,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
			local tc1=g1:GetFirst()
			g:Merge(g1)
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
			local g2=Duel.SelectMatchingCard(tp,s.mat2_sub,tp,LOCATION_MZONE,0,1,1,tc1,tc1:GetRank(),c,tp,tc1)
			g:Merge(g2)
		end
	elseif b1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g1=Duel.SelectMatchingCard(tp,s.mat1,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
		local tc1=g1:GetFirst()
		g:Merge(g1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g2=Duel.SelectMatchingCard(tp,s.mat1_sub,tp,LOCATION_MZONE,0,1,1,tc1,tc1:GetLevel(),c,tp,tc1)
		g:Merge(g2)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g1=Duel.SelectMatchingCard(tp,s.mat2,tp,LOCATION_MZONE,0,1,1,nil,c,tp)
		local tc1=g1:GetFirst()
		g:Merge(g1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local g2=Duel.SelectMatchingCard(tp,s.mat2_sub,tp,LOCATION_MZONE,0,1,1,tc1,tc1:GetRank(),c,tp,tc1)
		g:Merge(g2)
	end
	if g and #g==2 then
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

function s.tgtg(e,c)
	return c:IsSetCard(0xdb) or c:IsSetCard(0x2073)
end

function s.tdfilter(c)
	return c:IsSetCard(0xdb) and c:IsAbleToDeck() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end
function s.setfilter(c)
	return c:IsSetCard(0xdb) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.tdfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil)
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,2,0,0)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		local ct=g:FilterCount(Card.IsLocation,nil,LOCATION_DECK+LOCATION_EXTRA)
		if ct>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #sg>0 then
				local tc=sg:GetFirst()
				Duel.SSet(tp,tc)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
				e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
	end
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rc~=e:GetHandler() and re:IsActiveType(TYPE_MONSTER) 
		and (rc:IsSetCard(0xdb) or rc:IsSetCard(0x2073))
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
	local b2=Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4),aux.Stringid(id,5))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,4))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,5))+1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
	else
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_HAND)
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	else
		local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		if #g>0 then
			local sg=g:RandomSelect(tp,1)
			Duel.Destroy(sg,REASON_EFFECT)
		end
	end
end
