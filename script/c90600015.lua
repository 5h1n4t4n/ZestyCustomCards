-- Sky Striker Ace - Amenonuhoko
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon: 2 quái thú Level 4 "Sky Striker"
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2)
    c:EnableReviveLimit()

    -- Triệu hồi Xyz thay thế bằng 1 quái thú Link "Sky Striker" bạn điều khiển
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCondition(s.xyzcon)
    e0:SetTarget(s.xyztg)
    e0:SetOperation(s.xyzop)
    c:RegisterEffect(e0)

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; chọn mục tiêu 1 lá bài đối thủ điều khiển; đưa nó về tay
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú Xyz "Sky Striker" sử dụng lá bài này làm nguyên liệu nhận hiệu ứng (Quick Effect: Tách 1 nguyên liệu để trục xuất úp sấp 1 lá bài đối thủ điều khiển)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_XMATERIAL+EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCondition(s.matcon)
    e2:SetCost(s.matcost)
    e2:SetTarget(s.mattg)
    e2:SetOperation(s.matop)
    c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- LOGIC HỖ TRỢ & HIỆU ỨNG
--------------------------------------------------------------------------------

-- Thay thế điều kiện Xyz Summon bằng Link Monster
function s.xyzfilter(c,tp,xyzc)
    return c:IsFaceup() and c:IsType(TYPE_LINK) and c:IsSetCard(0x115) and c:IsCanBeXyzMaterial(xyzc,tp)
end
function s.xyzcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.CheckXyzMaterial(c,s.xyzfilter,1,1,1,e,tp)
end
function s.xyztg(e,tp,eg,ep,ev,re,r,rp,c)
    local g=Duel.SelectXyzMaterial(tp,c,s.xyzfilter,1,1,1,e,tp)
    if g then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end
function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if g then
        c:SetMaterial(g)
        Duel.Overlay(c,g)
        g:Delete()
    end
end

-- Hiệu ứng 1
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(1-tp) and chkc:IsAbleToHand() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOHAND)
    local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end

-- Hiệu ứng 2 (Áp dụng khi đang làm nguyên liệu cho Xyz Monster "Sky Striker")
function s.matcon(e)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return rc and rc:IsSetCard(0x115) and rc:IsType(TYPE_XYZ)
end
function s.matcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:CheckRemoveOverlayCard(tp,1,REASON_COST) end
    c:RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil,tp,POS_FACEDOWN) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil,tp,POS_FACEDOWN)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
    end
end