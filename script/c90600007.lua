-- Sky Striker Ace - Homusubi
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Link Summon: 1 quái thú "Sky Striker"
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),1,1)
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Nếu được Link Summon, thêm 1 Phép "Sky Striker" từ Deck, Mộ hoặc vùng trục xuất lên tay (trừ chính nó)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.lkcon)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Tăng 100 ATK cho mỗi Phép "Sky Striker" trong Mộ và vùng trục xuất của bạn
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Khi lá bài này được gửi xuống Mộ vì làm nguyên liệu Xyz (Đã thay thế sự kiện chuẩn an toàn tuyệt đối)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.mtcon)
    e3:SetCountLimit(1,{id,2})
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)

    -- HIỆU ỨNG 4: Trong End Phase, nếu lá bài này đang ở trong Mộ vì đã được gửi xuống đó trong lượt này -> Xáo nó vào Deck rồi rút 1 lá
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE+PHASE_END)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.tdcon)
    e4:SetTarget(s.tdtg)
    e4:SetOperation(s.tdop)
    c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG
--------------------------------------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and not c:IsCode(id) and c:IsAbleToHand()
        and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

function s.mtcon(e,tp,eg,ep,ev,re,r,rp)
    return r==REASON_XYZ
end

function s.atkval(e,c)
    return Duel.GetMatchingGroupCount(function(x) return x:IsSetCard(0x115) and x:IsType(TYPE_SPELL) end, c:GetControler(), LOCATION_GRAVE+LOCATION_REMOVED, 0, nil) * 100
end

-- Đã sửa: Xóa IsReason(REASON_TOGRAVE) vì hằng số này không tồn tại. Chỉ cần check TurnID là đủ.
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetTurnID()==Duel.GetTurnCount()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToDeck() and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,1,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 and c:IsLocation(LOCATION_DECK) then
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end