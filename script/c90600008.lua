-- Sky Striker Ace - Susanoo
-- ID: 90600008
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon chuẩn (2 quái thú Level 4 "Sky Striker") hoặc chồng lên 1 quái thú Link "Sky Striker" bạn điều khiển
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2,s.ovfilter,aux.Stringid(id,0))
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Tách 1 nguyên liệu; vô hiệu hóa quái thú ngửa của đối thủ (tối đa bằng số Phép "Sky Striker" trong Mộ)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.discost)
    e1:SetTarget(s.distg)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú Link "Sky Striker" dùng lá bài này làm nguyên liệu sẽ được gấp đôi ATK gốc
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetCondition(s.atkcon)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Nếu dùng làm nguyên liệu để Rank-Up thành quái thú Rank 8 "Sky Striker", quái thú đó không thể bị chọn làm mục tiêu bởi hiệu ứng bài
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.mtcon)
    e3:SetOperation(s.mtop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- ĐIỀU KIỆN TRIỆU HỒI
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_LINK,lc,SUMMON_TYPE_XYZ,tp)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 1 (VÔ HIỆU HÓA THEO SỐ LƯỢNG SPELL TRONG MỘ)
--------------------------------------------------------------------------------
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.spellcount(tp)
    return Duel.GetMatchingGroupCount(function(c) return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) end, tp, LOCATION_GRAVE, 0, nil)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then 
        local ct=s.spellcount(tp)
        return ct>0 and Duel.IsExistingMatchingCard(Card.IsCanBeDisabled,tp,0,LOCATION_MZONE,1,nil) 
    end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_MZONE)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local ct=s.spellcount(tp)
    if ct<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
    local g=Duel.SelectMatchingCard(tp,Card.IsCanBeDisabled,tp,0,LOCATION_MZONE,1,ct,nil)
    if #g>0 then
        local c=e:GetHandler()
        for tc in aux.Next(g) do
            Duel.NegateRelatedChain(tc,RESET_TURN_SET)
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetValue(RESET_TURN_SET)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e2)
        end
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 2 (GẤP ĐÔI ATK GỐC KHI LÀM NGUYÊN LIỆU LINK)
--------------------------------------------------------------------------------
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_LINK and rc and rc:IsSetCard(0x115) and rc:IsType(TYPE_LINK)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(rc:GetBaseAttack()*2)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 3 (KHÔNG THỂ BỊ CHỌN LÀM MỤC TIÊU KHI RANK-UP THÀNH RANK 8)
--------------------------------------------------------------------------------
function s.mtcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_XYZ and rc and rc:IsSetCard(0x115) and rc:IsRank(8)
end

function s.mtop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetValue(aux.tgoval)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1)
end