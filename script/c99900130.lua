-- Mausoleum of the Defier of Heaven
local s,id=GetID()
local ID_BOSS = 99900131 -- Qin Shi Huang
local ID_TOKEN = 99900136 -- Guardian Token

function s.initial_effect(c)
	-- (1) Kích hoạt: Negate sân, Draw bài, No damage
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- (2) Cấm Special Summon từ Mộ và Banish
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(1,1)
	e2:SetTarget(s.sumlimit)
	c:RegisterEffect(e2)

	-- (3) Bảo vệ BOSS (Qin Shi Huang)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.imtg)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- (4) Main Phase 1: Pay half LP -> Destroy -> SS Tokens
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN+CATEGORY_DESTROY)
	e4:SetType(EFFECT_TYPE_QUICK_O) -- Sửa từ IGNITION thành QUICK_O
	e4:SetCode(EVENT_FREE_CHAIN)	-- Thêm FREE_CHAIN bắt buộc cho Trap
	e4:SetRange(LOCATION_SZONE)
	e4:SetHintTiming(0,TIMING_MAIN_END)
	e4:SetCondition(s.tkcon)
	e4:SetCost(s.tkcost)
	e4:SetTarget(s.tktg)
	e4:SetOperation(s.tkop)
	c:RegisterEffect(e4)
end

s.listed_names={ID_BOSS,ID_TOKEN}

--------------------------------------------------------------------------------
-- (1) LOGIC ACTIVATION
--------------------------------------------------------------------------------
function s.damval(e,re,val,r,rp)
	return 0
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	
	-- Negate toàn sân trừ lá này
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end

	-- Draw bài: Mỗi 2 lá bị negate trên sân mỗi bên -> draw 1
	Duel.BreakEffect()
	local p1_ct = g:FilterCount(Card.IsControler, nil, tp)
	local p2_ct = g:FilterCount(Card.IsControler, nil, 1-tp)
	
	if p1_ct>=2 then Duel.Draw(tp,math.floor(p1_ct/2),REASON_EFFECT) end
	if p2_ct>=2 then Duel.Draw(1-tp,math.floor(p2_ct/2),REASON_EFFECT) end

	-- Không nhận damage (Battle & Effect) đến hết lượt
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetTargetRange(1,1)
	e3:SetValue(s.damval) -- Đã sửa: Truyền hàm damval trả về 0
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
end

--------------------------------------------------------------------------------
-- (2) LOGIC CẤM HỒI SINH
--------------------------------------------------------------------------------
function s.sumlimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
end

--------------------------------------------------------------------------------
-- (3) LOGIC BẢO VỆ BOSS
--------------------------------------------------------------------------------
function s.imtg(e,c)
	return c:IsFaceup() and c:IsCode(ID_BOSS) and c:GetOverlayCount()>=3
end

function s.efilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--------------------------------------------------------------------------------
-- (4) LOGIC TOKEN
--------------------------------------------------------------------------------
function s.tkcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCurrentPhase()==PHASE_MAIN1
end

function s.tkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end

function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,ID_TOKEN,0,TYPES_TOKEN,2000,2000,4,RACE_MACHINE,ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,0)
end

function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.Destroy(c,REASON_EFFECT)>0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 or not Duel.IsPlayerCanSpecialSummonMonster(tp,ID_TOKEN,0,TYPES_TOKEN,2000,2000,4,RACE_MACHINE,ATTRIBUTE_DARK) then return end
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
		for i=1,ft do
			local token=Duel.CreateToken(tp,ID_TOKEN)
			Duel.SpecialSummonStep(token,0,tp,tp,false,false,POS_FACEUP_ATTACK)
		end
		Duel.SpecialSummonComplete()
	end
end