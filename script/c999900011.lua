-- Magica: SYMPHONIC CADENZA THE SONG OF WAVE
-- ID: 999900011
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		= 0xc7d
local CARD_SAYAKA_STUDENT = 999900008
local COUNTER_NOTE	  = 0x1655

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_STUDENT}

function s.initial_effect(c)
	-- HOPT Activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.sayakafilter(c)
	return c:IsFaceup() and c:IsCode(CARD_SAYAKA_STUDENT)
end

function s.magicafilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.setfilter(c,e,tp)
	if c:IsLocation(LOCATION_REMOVED) and c:IsFacedown() then return false end
	if not (c:IsSetCard(SET_MAGICA) or c:IsSetCard(SET_SOULGEM)) then return false end
	if c:IsType(TYPE_MONSTER) then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE)
	elseif c:IsType(TYPE_SPELL+TYPE_TRAP) then
		return (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0) and c:IsSSetable()
	end
	return false
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local magica_ct=Duel.GetMatchingGroupCount(s.magicafilter,tp,LOCATION_ONFIELD,0,nil)
	local b1=magica_ct>0 and Duel.IsExistingMatchingCard(Card.IsCanAddCounter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil,COUNTER_NOTE,magica_ct)
	
	local note_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
	local sg_all=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
	local b2=note_ct>=2 and #sg_all>0

	if chk==0 then return b1 or b2 end

	-- Kháng Negate + Cấm CẢ HAI người chơi Chain nếu có Sayaka Miki the Magica Student
	if Duel.IsExistingMatchingCard(s.sayakafilter,tp,LOCATION_MZONE,0,1,nil) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_INACTIVATE)
		e1:SetValue(s.effectfilter)
		e1:SetReset(RESET_CHAIN)
		Duel.RegisterEffect(e1,tp)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CANNOT_DISEFFECT)
		Duel.RegisterEffect(e2,tp)
		Duel.SetChainLimit(s.chainlm)
	end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
	end

	if op==0 then
		e:SetCategory(CATEGORY_COUNTER)
		e:SetLabel(0)
	else
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
		-- Trả Cost: Remove up to 6 Note Counters từ sân ngay khi kích hoạt
		local max_set=math.min(3, #sg_all, math.floor(note_ct/2))
		local options={}
		for i=1, max_set do
			table.insert(options, i*2)
		end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local remove_ct=Duel.AnnounceNumber(tp,table.unpack(options))
		Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,remove_ct,REASON_COST)
		
		-- Lưu số Counter đã trừ để giải quyết ở bước Operation
		e:SetLabel(remove_ct)
	end
end

function s.effectfilter(e,ct)
	return ct==Duel.GetCurrentChain()
end

function s.chainlm(e,rp,tp)
	return false -- Cả 2 người chơi đều không được Chain
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local label=e:GetLabel()

	if label==0 then
		-- Hiệu ứng 1: Đặt Counter
		local ct=Duel.GetMatchingGroupCount(s.magicafilter,tp,LOCATION_ONFIELD,0,nil)
		if ct<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_COUNTER)
		local g=Duel.SelectMatchingCard(tp,Card.IsCanAddCounter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil,COUNTER_NOTE,ct)
		if #g>0 then
			g:GetFirst():AddCounter(COUNTER_NOTE,ct)
		end
	else
		-- Hiệu ứng 2: Set bài -> Hồi LP -> Chống sát thương
		local remove_ct=label
		local set_count=remove_ct/2

		for i=1, set_count do
			local sg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
			if #sg==0 then break end
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local tc=sg:Select(tp,1,1,nil):GetFirst()
			if tc then
				if tc:IsType(TYPE_MONSTER) then
					Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEDOWN_DEFENSE)
					Duel.ConfirmCards(1-tp,tc)
				else
					Duel.SSet(tp,tc)
				end
			end
		end
		Duel.SpecialSummonComplete()

		-- Hồi 200 LP cho mỗi 2 Note Counter còn lại trên sân
		local rem_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
		local gain_lp=math.floor(rem_ct/2)*200
		if gain_lp>0 then
			Duel.BreakEffect()
			Duel.Recover(tp,gain_lp,REASON_EFFECT)
		end

		-- Nếu đã gỡ đủ 6 Counter: Không chịu sát thương đến hết lượt tiếp theo
		if remove_ct==6 then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetCode(EFFECT_CHANGE_DAMAGE)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e1:SetTargetRange(1,0)
			e1:SetValue(0)
			e1:SetReset(RESET_PHASE+PHASE_END,2)
			Duel.RegisterEffect(e1,tp)

			local e2=e1:Clone()
			e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
			Duel.RegisterEffect(e2,tp)
		end
	end
end