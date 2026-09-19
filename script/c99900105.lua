-- Zhuge Liang, Omniscient Mecha Tactician
-- card id: 99900105
local s,id=GetID()
s.listed_series={0xb4c}

function s.initial_effect(c)
	-- 1) On Summon: look top 3, add 1 "Mecha Three Kingdom" to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg_summon)
	e1:SetOperation(s.thop_summon)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- 2) Quick Effect: Change opponent's monster effect to "Both players draw 1 card"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.qcon)
	e2:SetTarget(s.qtg)
	e2:SetOperation(s.qop)
	c:RegisterEffect(e2)

	-- 3) Destroy replace: banish 1 Mecha from GY instead
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DESTROY_REPLACE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTarget(s.reptg)
	e3:SetValue(s.repval)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)

	-- 4) Hand anti-brick: reveal this in hand, discard 1 other card, draw 1 (if you control no Mecha)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_HAND)
	e4:SetCountLimit(1,id+200)
	e4:SetCondition(s.handcon)
	e4:SetCost(s.handcost)
	e4:SetTarget(s.handtg)
	e4:SetOperation(s.handop)
	c:RegisterEffect(e4)
end

-- ########## effect 1: top3 search on summon ##########
function s.thfilter_any(c)
	return c:IsSetCard(0xb4c) and c:IsAbleToHand()
end
function s.thtg_summon(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return false end
		local g=Duel.GetDecktopGroup(tp,3)
		return g:IsExists(s.thfilter_any,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop_summon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
	local g=Duel.GetDecktopGroup(tp,3)
	Duel.ConfirmCards(tp,g)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=g:FilterSelect(tp,s.thfilter_any,1,1,nil)
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
		g:Sub(sg)
	end
	if #g>0 then
		Duel.SortDecktop(tp,tp,#g)
	end
end

-- ########## effect 2: quick change effect ##########
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and re:IsActiveType(TYPE_MONSTER)
end
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- Check xem cả 2 người chơi có thể rút bài được không (luật chuẩn khi đổi eff sang draw)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) and Duel.IsPlayerCanDraw(1-tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end
function s.qop(e,tp,eg,ep,ev,re,r,rp)
	-- Hàm thay đổi toàn bộ nội dung xử lý của Chain Link hiện tại (ev)
	local g=Group.CreateGroup()
	Duel.ChangeChainOperation(ev,s.changeop)
end
function s.changeop(e,tp,eg,ep,ev,re,r,rp)
	-- Đây là hiệu ứng mới sẽ đè lên hiệu ứng gốc của quái vật đối thủ
	Duel.Draw(tp,1,REASON_EFFECT)
	Duel.Draw(1-tp,1,REASON_EFFECT)
end

-- ########## effect 3: destruction replace ##########
function s.repfilter(c)
	return c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemoveAsCost()
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(function(tc) return tc:IsControler(tp) and tc:IsLocation(LOCATION_MZONE) and tc:IsSetCard(0xb4c) end,1,nil)
			and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then -- Đổi từ index 5 cũ sang index 3
		return true
	else
		return false
	end
end
function s.repval(e,c)
	return c:IsControler(e:GetHandlerPlayer()) and c:IsLocation(LOCATION_MZONE) and c:IsSetCard(0xb4c)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- ########## effect 4: hand anti-brick ##########
function s.mecha_filter_faceup(c)
	return c:IsFaceup() and c:IsSetCard(0xb4c) and c:IsType(TYPE_MONSTER)
end
function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.mecha_filter_faceup,tp,LOCATION_MZONE,0,1,nil)
end
function s.handcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:IsAbleToRemoveAsCost() and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,c)
	end
	Duel.ConfirmCards(1-tp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,c)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
	end
end
function s.handtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.handop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end