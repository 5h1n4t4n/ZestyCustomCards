-- Sky Striker Ace - The Fallen Automaton
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Điều kiện triệu hồi Link: 2 quái thú "Sky Striker"
    c:EnableReviveLimit()
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115,0x1115),2,2)

    -- HIỆU ỨNG 1: Khi được Triệu hồi Link -> Vô hiệu hóa 1 lá bài của đối thủ đến cuối lượt
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2 (BỊ ĐỘNG): Khi lá bài này ngửa trên sân, bạn được tính là không có quái thú ở Main Monster Zone khi kích hoạt bài "Sky Striker"
    -- Ta dùng hiệu ứng trường tác động lên người chơi để bỏ qua kiểm tra MMZ của các lá bài SetCard Sky Striker
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_ZOOM_SKY_STRIKER_CONDITION) -- Hoặc sử dụng cờ tuỳ chỉnh chống check zone
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(1,0)
    c:RegisterEffect(e2)

    -- Bổ sung thêm một lớp hiệu ứng cho phép các Spell Sky Striker luôn được coi như điều kiện "không có quái thú ở Main Monster Zone" thỏa mãn
    local e2_sub=Effect.CreateEffect(c)
    e2_sub:SetType(EFFECT_TYPE_FIELD)
    e2_sub:SetCode(369) -- Mã nội bộ engine cho phép check vùng Main Monster Zone trống giả lập
    e2_sub:SetRange(LOCATION_MZONE)
    e2_sub:SetTargetRange(LOCATION_MZONE,0)
    e2_sub:SetValue(1)
    c:RegisterEffect(e2_sub)

    -- HIỆU ỨNG 3: (Quick Effect - Twice per turn) Gửi 1 lá "Sky Striker" từ Tay/Sân xuống Mộ -> Vô hiệu hóa & trục xuất úp lá đối thủ kích hoạt
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(2,id)
    e3:SetCondition(s.discon)
    e3:SetCost(s.discost)
    e3:SetTarget(s.distg)
    e3:SetOperation(s.disop)
    c:RegisterEffect(e3)

    -- HIỆU ỨNG 4: Nếu có bài bị trục xuất bởi hiệu ứng lá này -> Lấy 1 lá "Sky Striker" khác tên từ Mộ/Vùng bị trục xuất lên tay
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_REMOVE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+100)
    e4:SetCondition(s.thcon)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and aux.NegateAnyFilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectTarget(tp,aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsCanBeDisabledByEffect(e) then
        local c=e:GetHandler()
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e2)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3
--------------------------------------------------------------------------------
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.cfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToGraveAsCost()
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,e:GetHandler())
    Duel.SendtoGrave(g,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsAbleToRemove(tp,POS_FACEDOWN) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local ec=re:GetHandler()
    if Duel.NegateEffect(ev) and ec and ec:IsRelateToEffect(re) then
        ec:CancelToGrave()
        Duel.Remove(ec,POS_FACEDOWN,REASON_EFFECT)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 4
--------------------------------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:GetHandler()==e:GetHandler()
end

function s.thfilter(c,banished_group)
    if not ((c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToHand()) then return false end
    return not banished_group or not banished_group:IsExists(Card.IsCode,1,nil,c:GetCode())
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,eg) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,eg)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end