-- Sky Striker Ace - Aether
-- ID: 02772337
local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ĐIỀU KIỆN TRIỆU HỒI ĐẶC BIỆT: Không thể Triệu hồi Thường/Úp. Phải Triệu hồi Đặc biệt bằng cách Hiến tế 3 quái thú "Sky Striker" trên sân
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CANNOT_DISABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_HAND)
    e0:SetCondition(s.spcon)
    e0:SetTarget(s.sptg)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)

    -- HIỆU ỨNG 1: (Quick Effect) Trục xuất 1 Phép "Sky Striker" ở Mộ -> Nhân hiệu ứng kích hoạt của lá Phép đó
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.copytg)
    e1:SetOperation(s.copyop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2A: Nếu có 3+ Phép dưới Mộ -> Có thể tấn công tất cả quái thú đối thủ 1 lần mỗi lá
    local e2a=Effect.CreateEffect(c)
    e2a:SetType(EFFECT_TYPE_SINGLE)
    e2a:SetCode(EFFECT_ATTACK_ALL)
    e2a:SetCondition(s.con3spell)
    e2a:SetValue(1)
    c:RegisterEffect(e2a)

    -- HIỆU ỨNG 2B: Nếu có 3+ Phép dưới Mộ -> Lá/hiệu ứng kích hoạt trên sân đối thủ không thể chỉ định các lá "Sky Striker" khác làm mục tiêu
    local e2b=Effect.CreateEffect(c)
    e2b:SetType(EFFECT_TYPE_FIELD)
    e2b:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2b:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
    e2b:SetRange(LOCATION_MZONE)
    e2b:SetTargetRange(LOCATION_ONFIELD,0)
    e2b:SetCondition(s.con3spell)
    e2b:SetTarget(s.tglimit_target)
    e2b:SetValue(s.tglimit_val)
    c:RegisterEffect(e2b)

    -- HIỆU ỨNG 3: Lá bài ngửa trên sân này rời sân do lá bài đối thủ -> Triệu hồi 1 quái "Sky Striker" Link từ Extra Deck hoặc Mộ
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.spcon3)
    e3:SetTarget(s.sptg3)
    e3:SetOperation(s.spop3)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- LOGIC TRIỆU HỒI ĐẶC BIỆT
--------------------------------------------------------------------------------
function s.rfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_MONSTER) and c:IsReleasable()
end

function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local rg=Duel.GetMatchingGroup(s.rfilter,tp,LOCATION_MZONE,0,nil)
    return aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkBList,0)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,c)
    local rg=Duel.GetMatchingGroup(s.rfilter,tp,LOCATION_MZONE,0,nil)
    local g=aux.SelectUnselectGroup(rg,e,tp,3,3,aux.ChkBList,1,tp,HINTMSG_RELEASE)
    if #g>0 then
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    end
    return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.Release(g,REASON_COST)
    g:DeleteGroup()
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.copyfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_SPELL) and c:IsAbleToRemove()
        and c:CheckActivateEffect(false,true,false)~=nil
end

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.copyfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.copyfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,s.copyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    local te,ceg,cep,cev,cre,cr,crp=g:GetFirst():CheckActivateEffect(false,true,true)
    Duel.ClearTargetCard()
    e:SetProperty(te:GetProperty())
    local tg=te:GetTarget()
    if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
    te:SetLabelObject(e:GetLabelObject())
    e:SetLabelObject(te)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

function s.copyop(e,tp,eg,ep,ev,re,r,rp)
    local te=e:GetLabelObject()
    if not te then return end
    local tc=te:GetHandler()
    if tc:IsRelateToEffect(e) and Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 then
        e:SetLabelObject(te:GetLabelObject())
        local op=te:GetOperation()
        if op then op(e,tp,eg,ep,ev,re,r,rp) end
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2
--------------------------------------------------------------------------------
function s.con3spell(e)
    return Duel.GetMatchingGroupCount(Card.IsType,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3
end

function s.tglimit_target(e,c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c~=e:GetHandler()
end

function s.tglimit_val(e,re,rp)
    return rp~=e:GetHandlerPlayer() and re:GetHandler():IsOnField()
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3
--------------------------------------------------------------------------------
function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousPosition(POS_FACEUP)
        and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.spfilter3(c,e,tp)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_LINK)
        and (c:IsLocation(LOCATION_GRAVE) or Duel.GetLocationCountFromEx(tp,tp,nil,c)>0)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter3,tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter3),tp,LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end