-- ETERNAL: THE MAGICA LAST GRACE
-- ID: 999900004
local s,id=GetID()

local SET_MAGICA = 0x654

s.listed_series={SET_MAGICA}

function s.initial_effect(c)
	-- Kích hoạt Phép: Reveal 10 lá "Magica" từ Hand/Deck -> Phá hủy toàn bộ bài đối phương
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- REVEAL 10 "MAGICA" CARDS COST
--------------------------------------------------------------------------------
function s.cfilter(c)
	return c:IsSetCard(SET_MAGICA)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil)
	if chk==0 then return #g>=10 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local sg=g:Select(tp,10,10,nil)
	Duel.ConfirmCards(1-tp,sg)
	Duel.ShuffleDeck(tp)
end

--------------------------------------------------------------------------------
-- DESTROY ALL OPPONENT'S CARDS
--------------------------------------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
