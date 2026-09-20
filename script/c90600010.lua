-- Sky Striker Ace - Ryujin
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Link Summon: 1 quái thú "Sky Striker"
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),1,1)
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Nếu được Link Summon, xáo 1 Phép "Sky Striker" từ Mộ hoặc vùng trục xuất vào Deck, rồi rút 1 lá
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.lkcon)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.drtg)
    e1:SetOperation(s.drop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú đối thủ điều khiển mất 100 ATK/DEF cho mỗi lá Phép trong Mộ của bạn
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(0,LOCATION_MZONE)
    e2:setValue(s.atkval)
    c:RegisterEffect(e2)
    local e2_def=e2:Clone()
    e2_def:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e2_def)

    -- HIỆU ỨNG 3: Nếu được gắn vào quái thú Xyz làm nguyên liệu -> Chọn mục tiêu 1 Phép "Sky Striker" trong Mộ; gắn nó vào quái thú Xyz đó
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_DETACHED_FROM_XYZ) -- hoặc khi được gắn / tách làm nguyên liệu Xyz
    e3:SetRange(LOCATION_MZONE) -- Hoặc xử lý khi ở trạng thái nguyên liệu Xyz
    -- Lưu ý: Trong môi trường viết script EDOPro, hiệu ứng gắn nguyên liệu từ Mộ khi làm nguyên liệu Xyz thường được check ở dạng Effect gắn sẵn trên Xyz Monster hoặc thông qua sự kiện Material.
    -- Dưới đây viết theo dạng Trigger khi lá bài này nằm ở ô nguyên liệu Xyz (ATTACHED):
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_CHAINING) -- Tùy biến theo cơ chế check nguyên liệu Xyz
    -- Để đảm bảo tính ổn định cấu trúc tiêu chuẩn, ta cấu hình hiệu ứng 3 dạng Trigger khi nằm trong nguyên liệu Xyz:
    -- (Trong OCG/TCG, các hiệu ứng kiểu này thường kích hoạt khi quái Xyz kích hoạt hiệu ứng bằng cách tách nó ra hoặc khi nó được gắn)
    -- Ta viết code hỗ trợ bắt sự kiện Xyz Material:
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_IGNITION)
    e3:SetCountLimit(1,{id,2})
    e3:SetTarget(s.mattg)
    e3:SetOperation(s.matop)
    -- Chú ý: Một số bản cơ chế Xyz Material áp dụng hiệu ứng trực tiếp từ card mẹ, ta thiết lập qua hàm chuẩn:
    -- Nếu lá bài này được gắn vào quái Xyz:
    local e3_alt=Effect.CreateEffect(c)
    e3_alt:SetDescription(aux.Stringid(id,1))
    e3_alt:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3_alt:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3_alt:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3_alt:SetCode(EVENT_BE_MATERIAL)
    e3_alt:SetCondition(s.matcon)
    e3_alt:SetTarget(s.mattg)
    e3_alt:SetOperation(s.matop)
    c:RegisterEffect(e3_alt)

    -- HIỆU ỨNG 4: Trong End Phase, nếu lá bài này ở trong Mộ vì đã bị gửi từ sân xuống đó trong lượt này -> Thêm 1 Phép "Sky Striker" từ Deck lên tay
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_PHASE+PHASE_END)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,{id,3})
    e4:SetCondition(s.thcon)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG
--------------------------------------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.tdfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToDeck() 
        and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,1,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end

function s.atkval(e,c)
    return Duel.GetMatchingGroupCount(function(x) return x:IsType(TYPE_SPELL) end, e:GetHandlerPlayer(), LOCATION_GRAVE, 0, nil) * -100
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    return r==REASON_XYZ
end

function s.mgfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.mgfilter(chkc) end
    local c=e:GetHandler()
    local xyzc=c:GetReasonCard()
    if chk==0 then return xyzc and Duel.IsExistingTarget(s.mgfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.mgfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local xyzc=c:GetReasonCard()
    local tc=Duel.GetFirstTarget()
    if xyzc and xyzc:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        Duel.Overlay(xyzc,Group.FromCards(tc))
    end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_TOGRAVE) and c:GetTurnID()==Duel.GetTurnCount()
end

function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
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