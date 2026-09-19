-- Sky Striker Mobilize - Advanced
-- ID: 02772337
local s,id=GetID()

function s.initial_effect(c)
    -- Kích hoạt lá bài (Phép Tốc độ cao / Quick-Play Spell)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DECKDES)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_END_PHASE)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- LOGIC KÍCH HOẠT
--------------------------------------------------------------------------------
-- Điều kiện: Không điều khiển quái thú nào ở Ô Quái Thú Chính (Main Monster Zone)
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MMZONE,0)==0
end

-- Bộ lọc lấy lá bài "Sky Striker" từ Deck (trừ lá này)
function s.thfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- 1. Lấy 1 lá "Sky Striker" từ Deck lên tay
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
        Duel.ConfirmCards(1-tp,g)
        
        -- 2. Nếu dưới Mộ có từ 3 Phép trở lên -> Có thể lật 3 lá đầu Deck
        local spell_count=Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
        if spell_count>=3 and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 
            and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            
            Duel.BreakEffect()
            Duel.ConfirmDecktop(tp,3)
            local dg=Duel.GetDecktopGroup(tp,3)
            if #dg>0 then
                -- Lọc các lá "Sky Striker" trong 3 lá vừa lật
                local sg=dg:Filter(function(c) return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToHand() end, nil)
                if #sg>0 then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                    local th=sg:Select(tp,1,1,nil)
                    Duel.SendtoHand(th,nil,REASON_EFFECT)
                    Duel.ConfirmCards(1-tp,th)
                    dg:Sub(th)
                end
                -- Gửi tất cả các lá còn lại trong 3 lá đó xuống Mộ
                if #dg>0 then
                    Duel.SendtoGrave(dg,REASON_EFFECT)
                end
            end
        end
    end
end