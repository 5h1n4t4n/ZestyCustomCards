-- Rising HERO Reglam
-- ID: 888700009
local s,id=GetID()

local SET_RISING_HERO	 = 0xff8
local CARD_POLYMERIZATION = 24094653

s.listed_series={SET_RISING_HERO}
s.listed_names={CARD_POLYMERIZATION}

function s.initial_effect(c)
	-- Khi bị gửi xuống GY: Lấy 1 lá Phép "Rising" hoặc 1 "Polymerization" từ Deck lên tay
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetCountLimit(1,id) 
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- SEARCH LOGIC
--------------------------------------------------------------------------------
function s.thfilter(c)
	return ((c:IsSetCard(SET_RISING_HERO) and c:IsType(TYPE_SPELL)) or c:IsCode(CARD_POLYMERIZATION))
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
