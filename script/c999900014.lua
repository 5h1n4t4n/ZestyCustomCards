-- Mami the Magica Mahou Shoujo
-- ID: 999900014
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		 = 0xc7d
local CARD_MAMI_STUDENT   = 999900013
local CARD_MAMI_WITCH	 = 999900015
local TOKEN_GRIEF_SEED	= 999900006

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_MAMI_STUDENT, CARD_MAMI_WITCH, TOKEN_GRIEF_SEED}

function s.initial_effect(c)
	c:EnableReviveLimit()

	-- ĐIỀU KIỆN SUMMON: Bắt buộc gọi bằng hiệu ứng của Mami Tomoe the Magica Student
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- 1. Quick Effect trên tay (Lượt đối phương): Reveal -> Special Summon Token -> Destroy Tokens -> Banish Extra Deck or Destroy 2 cards (Once per Duel)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e1:SetCondition(s.handcon)
	e1:SetCost(s.handcost)
	e1:SetTarget(s.handtg)
	e1:SetOperation(s.handop)
	c:RegisterEffect(e1)

	-- 2. Quick Effect trên sân: Target 1 quái thú -> Gửi xuống GY & Gây damage -> Special Summon Mami Witch -> Thu hồi về tay (HOPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DAMAGE+CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

function s.splimit(e,se,sp,st)
	return se and se:GetHandler() and se:GetHandler():IsCode(CARD_MAMI_STUDENT)
end

--------------------------------------------------------------------------------
-- FILTER HELPER FUNCTIONS
--------------------------------------------------------------------------------
function s.mamistudentfilter(c)
	return c:IsFaceup() and c:IsCode(CARD_MAMI_STUDENT)
end

function s.griefseedfilter(c)
	return c:IsFaceup() and c:IsCode(TOKEN_GRIEF_SEED)
end

function s.witchfilter(c,e,tp)
	return c:IsCode(CARD_MAMI_WITCH) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end

-- Kiểm tra mục tiêu có hợp lệ và đảm bảo người chơi có ô trống để gọi Witch
function s.tgtfilter(c,e,tp)
	if not c:IsAbleToGrave() then return false end
	if c:IsControler(tp) then
		return Duel.GetMZoneCount(tp,c)>0
	else
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
end

--------------------------------------------------------------------------------
-- EFFECT 1: IN-HAND QUICK EFFECT (OPPONENT'S TURN / OPD)
--------------------------------------------------------------------------------
function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==1-tp
end

function s.handcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_PUBLIC)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOHAND+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

function s.handtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,SET_MAGICA,TYPES_TOKEN,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_LIGHT)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)

	-- Nếu điều khiển Mami Student: Không thể bị Negate và Chống phản hồi (Unrespondable)
	if Duel.IsExistingMatchingCard(s.mamistudentfilter,tp,LOCATION_MZONE,0,1,nil) then
		e:SetProperty(EFFECT_FLAG_CANNOT_INACTIVATE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
		Duel.SetChainLimit(s.chainlm)
	else
		e:SetProperty(0)
	end
end

function s.chainlm(e,rp,tp)
	return false
end

function s.handop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0
		or not Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_GRIEF_SEED,SET_MAGICA,TYPES_TOKEN,300,300,1,RACE_SPELLCASTER,ATTRIBUTE_LIGHT) then return end

	local token=Duel.CreateToken(tp,TOKEN_GRIEF_SEED)
	if Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		
		-- Chọn phá hủy tối đa 4 Grief Seed Token trên sân
		local tg=Duel.GetMatchingGroup(s.griefseedfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
		local des_ct=0
		if #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local sg=tg:Select(tp,1,4,nil)
			des_ct=Duel.Destroy(sg,REASON_EFFECT)
		end

		local ext_g=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
		-- Nếu phá hủy thành công Token VÀ Extra Deck đối phương có từ 4 lá trở lên
		if des_ct>0 and #ext_g>=4 then
			Duel.ConfirmCards(tp,ext_g)
			
			-- Chọn 2 lá banish ngửa
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local g1=ext_g:Select(tp,2,2,nil)
			ext_g:Sub(g1)
			
			-- Chọn 2 lá banish úp
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local g2=ext_g:Select(tp,2,2,nil)

			Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)
			Duel.Remove(g2,POS_FACEDOWN,REASON_EFFECT)
		else
			-- Nếu không phá hủy Token hoặc không banish đủ Extra Deck -> Phá hủy 2 lá trên sân
			local dg=Duel.GetMatchingGroup(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
			if #dg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
				local sg2=dg:Select(tp,math.min(#dg,2),math.min(#dg,2),nil)
				Duel.Destroy(sg2,REASON_EFFECT)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- EFFECT 2: SEND TO GY & BURN DAMAGE & SPECIAL SUMMON WITCH (HOPT)
--------------------------------------------------------------------------------
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.tgtfilter(chkc,e,tp) end
	if chk==0 then
		return Duel.IsExistingTarget(s.tgtfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.witchfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,s.tgtfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local lv=tc:GetLevel()
		if tc:IsType(TYPE_XYZ) or tc:IsType(TYPE_LINK) then lv=0 end
		
		-- Chỉ cần gửi thành công quái thú đi (không bắt buộc phải rơi vào GY)
		if Duel.SendtoGrave(tc,REASON_EFFECT)>0 then
			if lv>0 then
				Duel.Damage(1-tp,lv*500,REASON_EFFECT)
			end
			Duel.BreakEffect()
			
			if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local g=Duel.SelectMatchingCard(tp,s.witchfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
				local sc=g:GetFirst()
				if sc and Duel.SpecialSummon(sc,0,tp,tp,true,true,POS_FACEUP)>0 then
					sc:CompleteProcedure()
					if c:IsRelateToEffect(e) and c:IsAbleToHand() then
						Duel.BreakEffect()
						Duel.SendtoHand(c,nil,REASON_EFFECT)
					end
				end
			end
		end
	end
end