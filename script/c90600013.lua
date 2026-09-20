-- Sky Striker Ace - Corrupted Striker
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

    -- Giới hạn chỉ được Special Summon 1 lần mỗi lượt
    c:SetSPSummonOnce(id)

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; Đặc biệt triệu hồi 1 quái thú Level 4 "Sky Striker" từ tay, Deck hoặc Mộ
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,{id,1})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú "Sky Striker" được Link Summon sử dụng lá bài này làm nguyên liệu không thể bị phá hủy bởi hiệu ứng bài
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.immtg)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Nếu lá bài này được dùng làm nguyên liệu cho việc Xyz Summon quái Rank 8 "Sky Striker", quái đó không thể bị phá hủy bởi hiệu ứng bài
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.efcon)
    e3:SetOperation(s.efop)
    c:RegisterEffect(e3)
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
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.spfilter(c,e,tp)
    return c:IsLevel(4) and c:IsSetCard(0x115) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Hiệu ứng 2
function s.immtg(e,c)
    return c:IsType(TYPE_LINK) and c:IsSetCard(0x115) and c:GetMaterial():IsContains(e:GetHandler())
end

-- Hiệu ứng 3
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_XYZ and rc:IsRank(8) and rc:IsSetCard(0x115)
end
function s.efop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end