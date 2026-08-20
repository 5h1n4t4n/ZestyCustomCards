--Trishula, Lord of the Blizzard
local s,id=GetID()

s.listed_series={0x2f}

function s.initial_effect(c)
	--------------------------------------------------
	-- Synchro Summon
	-- 1 Tuner + 1+ non-Tuner "Ice Barrier" monsters
	--------------------------------------------------
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(s.ntfilter),1,99)

	--------------------------------------------------
	-- Other "Ice Barrier" cards you control
	-- cannot be targeted by opponent's card effects
	--------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_TARGET_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_ONFIELD,0)
	e1:SetTarget(s.tgtg)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)

	--------------------------------------------------
	-- If an "Ice Barrier" card(s) you control would
	-- be destroyed by an opponent's card effect,
	-- you can banish 1 WATER monster from your GY instead
	--------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)

	--------------------------------------------------
	-- Negate opponent's card/effect
	-- Then banish up to 1 card from:
	-- Field, random Hand, and GY
	--------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)

	--------------------------------------------------
	-- Quick Effect:
	-- Banish this card + 1 "Ice Barrier" Synchro
	-- from GY, then Special Summon 1 "Ice Barrier"
	-- Synchro Monster from Extra Deck.
	-- Treated as a Synchro Summon.
	--------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

--------------------------------------------------
-- Synchro material
--------------------------------------------------

function s.ntfilter(c,scard,sumtype,tp)
	return c:IsSetCard(0x2f,scard,sumtype,tp)
end

--------------------------------------------------
-- Target protection
--------------------------------------------------

function s.tgtg(e,c)
	return c~=e:GetHandler()
		and c:IsFaceup()
		and c:IsSetCard(0x2f)
end

--------------------------------------------------
-- Destruction replacement
--------------------------------------------------

function s.repfilter(c,tp)
	return c:IsAttribute(ATTRIBUTE_WATER)
		and c:IsAbleToRemove()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return rp==1-tp
			and eg:IsExists(
				function(c)
					return c:IsSetCard(0x2f)
				end,
				1,nil
			)
			and Duel.IsExistingMatchingCard(
				s.repfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,nil,tp
			)
	end

	return rp==1-tp
		and eg:IsExists(
			function(c)
				return c:IsSetCard(0x2f)
			end,
			1,nil
		)
end

function s.repval(e,c)
	return c:IsSetCard(0x2f)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(
		tp,
		s.repfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,1,
		nil,
		tp
	)

	if #g>0 then
		Duel.Remove(
			g,
			POS_FACEUP,
			REASON_EFFECT+REASON_REPLACE
		)
	end
end

--------------------------------------------------
-- Negate
--------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainDisablable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsChainDisablable(ev)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_NEGATE,
		eg,
		1,
		0,
		0
	)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.NegateActivation(ev) then
		return
	end

	local opp=1-tp

	--------------------------------------------------
	-- Banish up to 1 card from opponent's field
	--------------------------------------------------
	local fg=Duel.GetMatchingGroup(
		Card.IsAbleToRemove,
		opp,
		LOCATION_ONFIELD,
		0,
		nil
	)

	if #fg>0 then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local sg=Duel.SelectMatchingCard(
			tp,
			Card.IsAbleToRemove,
			opp,
			LOCATION_ONFIELD,
			0,
			0,1,
			nil
		)

		if #sg>0 then
			Duel.Remove(
				sg,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end

	--------------------------------------------------
	-- Banish up to 1 random card from opponent's hand
	--------------------------------------------------
	local hg=Duel.GetFieldGroup(
		opp,
		LOCATION_HAND,
		0
	)

	if #hg>0 then
		local op=Duel.SelectOption(
			tp,
			aux.Stringid(id,0),
			aux.Stringid(id,1)
		)

		if op==0 then
			local rc=Duel.RandomSelect(
				opp,
				hg,
				1
			)

			if rc and #rc>0 then
				Duel.Remove(
					rc,
					POS_FACEUP,
					REASON_EFFECT
				)
			end
		end
	end

	--------------------------------------------------
	-- Banish up to 1 card from opponent's GY
	--------------------------------------------------
	local gg=Duel.GetMatchingGroup(
		Card.IsAbleToRemove,
		opp,
		LOCATION_GRAVE,
		0,
		nil
	)

	if #gg>0 then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_REMOVE
		)

		local sg=Duel.SelectMatchingCard(
			tp,
			Card.IsAbleToRemove,
			opp,
			LOCATION_GRAVE,
			0,
			0,1,
			nil
		)

		if #sg>0 then
			Duel.Remove(
				sg,
				POS_FACEUP,
				REASON_EFFECT
			)
		end
	end
end

--------------------------------------------------
-- Special Summon procedure
--------------------------------------------------

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

function s.spfilter(c,e,tp)
	return c~=e:GetHandler()
		and c:IsSetCard(0x2f)
		and c:IsType(TYPE_SYNCHRO)
		and c:IsFaceup()
		and c:IsAbleToRemove()
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_SYNCHRO,
			tp,
			true,
			false
		)
end

function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x2f)
		and c:IsType(TYPE_SYNCHRO)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_SYNCHRO,
			tp,
			true,
			false
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsFaceup()
			and c:IsAbleToRemove()
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,nil,e,tp
			)
			and Duel.IsExistingMatchingCard(
				s.spfilter2,
				tp,
				LOCATION_EXTRA,
				0,
				1,nil,e,tp
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		c,
		1,
		tp,
		LOCATION_MZONE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsFaceup()
		or not c:IsRelateToEffect(e)
	then
		return
	end

	--------------------------------------------------
	-- Select the Ice Barrier Synchro in GY
	--------------------------------------------------
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,1,
		nil,
		e,
		tp
	)

	local tc=g:GetFirst()

	if not tc then
		return
	end

	--------------------------------------------------
	-- Select Extra Deck monster
	--------------------------------------------------
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local sg=Duel.SelectMatchingCard(
		tp,
		s.spfilter2,
		tp,
		LOCATION_EXTRA,
		0,
		1,1,
		nil,
		e,
		tp
	)

	local sc=sg:GetFirst()

	if not sc then
		return
	end

	--------------------------------------------------
	-- Banish this card and the selected GY monster
	--------------------------------------------------
	local rg=Group.FromCards(c,tc)

	if Duel.Remove(
		rg,
		POS_FACEUP,
		REASON_EFFECT
	)~=2 then
		return
	end

	--------------------------------------------------
	-- Special Summon the selected Synchro
	--------------------------------------------------
	if Duel.SpecialSummon(
		sc,
		SUMMON_TYPE_SYNCHRO,
		tp,
		tp,
		true,
		false,
		POS_FACEUP
	)>0 then
		sc:CompleteProcedure()
	end
end