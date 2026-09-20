-- Sky Striker Ace - Divine Zero
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon: 3 quái thú Level 8
    Xyz.AddProcedure(c,nil,8,3)
    c:EnableReviveLimit()

    -- Triệu hồi Xyz thay thế bằng "Rank-Up-Magic Sky Striker Rising"
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.rumcon)
    e0:SetTarget(s.rumtg)
    e0:SetOperation(s.rumop)
    c:RegisterEffect(e0)

    -- HIỆU ỨNG 1 (Quick Effect): Tách 2 nguyên liệu; vô hiệu hóa hiệu ứng
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Nếu bài đối thủ bị trục xuất úp sấp bởi hiệu ứng bài bạn -> Thêm 1 Phép "Sky Striker"
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_REMOVE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Nếu bài khác bạn điều khiển rời sân do hiệu ứng của đối thủ -> Chọn 1 bài "Sky Striker" gắn làm nguyên liệu
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.matcon)
    e3:SetTarget(s.mattg)
    e3:SetOperation(s.matop)
    c:RegisterEffect(e3)

    -- HIỆU ỨNG 4: Nếu bị tiêu diệt bởi bài đối thủ -> Đặc biệt triệu hồi 1 quái "Sky Striker", rồi thêm 1 Phép
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,3))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCondition(s.spcon)
    e4:SetTarget(s.sptg)
    e4:SetOperation(s.spop)
    c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- LOGIC HỖ TRỢ & HIỆU ỨNG
--------------------------------------------------------------------------------

-- RUM Check
function s.rumfilter(c,e,tp,xyzc)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsCanBeXyzMaterial(xyzc,tp)
end
function s.rumcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.CheckXyzMaterial(c,s.rumfilter,1,1,1,e,tp)
end
function s.rumtg(e,tp,eg,ep,ev,re,r,rp,c)
    local g=Duel.SelectXyzMaterial(tp,c,s.rumfilter,1,1,1,e,tp)
    if g then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end
function s.rumop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if g then
        c:SetMaterial(g)
        Duel.Overlay(c,g)
        g:Delete()
    end
end

-- Hiệu ứng 1
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3 then
        local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
        if #g>0 then
            Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
        end
    end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3 then
        local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,nil)
        if #g>0 then
            Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
        end
    end
end

-- Hiệu ứng 2
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and eg:IsExists(function(c) return c:IsReason(REASON_EFFECT) and c:IsFacedown() and c:IsLocation(LOCATION_REMOVED) and c:IsControler(1-tp) end,1,nil)
end
function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc)
    end
end

-- Hiệu ứng 3
function s.matfilter_check(c,tp,ec)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_FIELD) and c~=ec and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()~=tp
end
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.matfilter_check,1,nil,tp,e:GetHandler())
end
function s.attfilter(c)
    return c:IsSetCard(0x115) and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.attfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.attfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.attfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        Duel.Overlay(c,Group.FromCards(tc))
    end
end

-- Hiệu ứng 4
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_XYZ) and rp~=tp and c:IsReason(REASON_DESTROY) and c:GetReasonPlayer()~=tp
end
function s.spfilter(c,e,tp)
    return c:IsSetCard(0x115) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED))
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g1=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g1>0 and Duel.SpecialSummon(g1,0,tp,tp,false,false,POS_FACEUP)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g2=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
        if #g2>0 then
            Duel.SendtoHand(g2,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g2)
        end
    end
end