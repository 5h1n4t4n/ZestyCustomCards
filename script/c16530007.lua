-- Cyberdark Serpent
local s,id=GetID()

function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Fusion Materials: 1 "Cyberdark" monster + 1 Dragon or Machine monster
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_CYBERDARK),s.ffilter)

	-- Special Summon procedure from Extra Deck by Tributing 1 equipped Dragon/Machine
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	local proc_tg = s.sptg
	e1:SetTarget(proc_tg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Special Summon 1 "Cyberdark" monster from Deck and equip this card
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)

	-- While equipped: Quick Xyz Summon using this card and equipped monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.xyzcon)
	e3:SetTarget(s.xyztg)
	e3:SetOperation(s.xyzop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_CYBERDARK}

function s.ffilter(c,fc,sumtype,tp,sub,mg,sg)
	return c:IsRace(RACE_DRAGON|RACE_MACHINE,fc,sumtype,tp)
end

function s.tribfilter(c,tp)
	return c:IsFaceup() and c:IsControler(tp) and c:IsRace(RACE_DRAGON|RACE_MACHINE)
		and c:IsReleasable() and c:GetEquipGroup():IsExists(Card.IsType,1,nil,TYPE_MONSTER)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local rg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_MZONE,0,nil,tp)
	return Duel.GetLocationCountFromEx(tp,tp,rg,c)>0 and #rg>0
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_MZONE,0,nil,tp)
	local g=aux.SelectUnselectGroup(rg,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_RELEASE,nil,nil,true)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.Release(g,REASON_COST|REASON_MATERIAL)
	g:DeleteGroup()
end

function s.cdfilter(c,e,tp)
	return c:IsSetCard(SET_CYBERDARK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.cdfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,tp,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.cdfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
			if Duel.Equip(tp,c,tc) then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
				e1:SetCode(EFFECT_EQUIP_LIMIT)
				e1:SetValue(function(e,c) return c==tc end)
				e1:SetReset(RESET_EVENT|RESETS_STANDARD)
				c:RegisterEffect(e1)
			end
		end
	end
end

function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
	local ec=e:GetHandler():GetEquipTarget()
	return ec and ec:IsFaceup() and rp==1-tp
end

function s.xyzfilter(c,e,tp,rk)
	return c:IsType(TYPE_XYZ) and c:IsRank(rk) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if chk==0 then
		return ec and ec:GetLevel()>0
			and Duel.GetLocationCountFromEx(tp,tp,ec,TYPE_XYZ)>0
			and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,ec:GetLevel())
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipTarget()
	if not c:IsRelateToEffect(e) or not ec or not ec:IsFaceup() then return end
	local rk=ec:GetLevel()
	if rk<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,rk):GetFirst()
	if sc then
		local mg=Group.FromCards(ec,c)
		Duel.Overlay(sc,mg)
		Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
