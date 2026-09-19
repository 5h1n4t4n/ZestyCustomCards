-- Sky Striker Ace - Homura
-- ID: 02772337
local s,id=GetID()

function s.initial_effect(c)
    -- Luôn được coi là lá bài "Sky Striker Ace - Raye" (ID: 26082229)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetValue(26082229)
    c:RegisterEffect(e0)

    -- HIỆU ỨNG 1: Tự Triệu hồi Đặc biệt từ tay khi không có quái thú hoặc chỉ có quái thú "Sky Striker"
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon1)
    e1:SetTarget(s.sptg1)
    e1:SetOperation(s.spop1)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: (Quick Effect) Hiến tế -> Triệu hồi 1 quái thú "Sky Striker" Xyz Rank 4 -> Gắn tối đa 2 Phép "Sky Striker" làm nguyên liệu
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.xyzcost)
    e2:SetTarget(s.xyztg)
    e2:SetOperation(s.xyzop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Khi ở Mộ + quái thú "Sky Striker" rời sân bởi hiệu ứng đối thủ -> Tự Triệu hồi Đặc biệt + Lấy 1 Phép "Sky Striker" lên tay
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.gycon)
    e3:SetTarget(s.gytg)
    e3:SetOperation(s.gyop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.cfilter(c)
    return c:IsFaceup() and not (c:IsSetCard(0x115) or c:IsSetCard(0x1115))
end

function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)
    return #g==0 or not g:IsExists(s.cfilter,1,nil)
end

function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2
--------------------------------------------------------------------------------
function s.xyzcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsReleasable() end
    Duel.Release(c,REASON_COST)
end

function s.xyzfilter(c,e,tp)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_XYZ) and c:IsRank(4)
        and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.matfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_SPELL)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
        local spell_count=Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
        if spell_count>=3 then
            local matg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
            if #matg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                Duel.BreakEffect()
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
                local sg=aux.SelectUnselectGroup(matg,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_XMATERIAL)
                if #sg>0 then
                    Duel.Overlay(tc,sg)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 3
--------------------------------------------------------------------------------
function s.gyfilter(c,tp)
    return (c:IsPreviousSetCard(0x115) or c:IsPreviousSetCard(0x1115))
        and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousControler(tp)
        and c:IsReason(REASON_EFFECT)
        and c:GetReasonPlayer()==1-tp
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
    return not Duel.IsDamageStep() and eg:IsExists(s.gyfilter,1,nil,tp)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
        local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
        if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local sg=g:Select(tp,1,1,nil)
            if #sg>0 then
                Duel.SendtoHand(sg,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,sg)
            end
        end
    end
end