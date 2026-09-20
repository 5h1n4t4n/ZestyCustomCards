-- Sky Striker Ace - Corrupted Striker
-- ID: 90600013
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon: 2 quái thú Level 4 "Sky Striker" HOẶC chồng lên 1 quái thú Link "Sky Striker" bạn điều khiển
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2,s.ovfilter,aux.Stringid(id,0))
    c:EnableReviveLimit()

    -- Giới hạn chỉ được Special Summon 1 lần mỗi lượt
    c:SetSPSummonOnce(id)

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; Đặc biệt triệu hồi 1 quái thú Level 4 "Sky Striker" từ tay, Deck hoặc Mộ
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,{id,1})
    e1:SetCost(s.spcost)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú Link "Sky Striker" sử dụng lá này làm nguyên liệu không thể bị phá hủy bởi hiệu ứng bài
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetCondition(s.lkcon)
    e2:SetOperation(s.lkop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Quái thú Xyz Rank 8 "Sky Striker" sử dụng lá này làm nguyên liệu không thể bị phá hủy bởi hiệu ứng bài
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.efcon)
    e3:SetOperation(s.efop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- ĐIỀU KIỆN TRIỆU HỒI
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_LINK,lc,SUMMON_TYPE_XYZ,tp)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 1: ĐẶC BIỆT TRIỆU HỒI QUÁI THÚ "SKY STRIKER"
--------------------------------------------------------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.spfilter(c,e,tp)
    return c:IsLevel(4) and c:IsSetCard(0x115) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 2: TRAO HIỆU ỨNG CHO QUÁI LINK
--------------------------------------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_LINK and rc and rc:IsSetCard(0x115)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 3: TRAO HIỆU ỨNG CHO QUÁI XYZ RANK 8
--------------------------------------------------------------------------------
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_XYZ and rc and rc:IsRank(8) and rc:IsSetCard(0x115)
end

function s.efop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end