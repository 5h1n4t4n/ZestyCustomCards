-- Meteor Rush Dragon
local s,id=GetID()
function s.initial_effect(c)
    -- This card is always treated as a "Red-Eyes" card
    c:AddSetcodesRule(id,false,0x3b)

    -- If this card is used for an Xyz Summon, it can be treated as 2 materials
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_DOUBLE_XYZ_MATERIAL)
    e1:SetOperation(s.xyzval)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- 1. Reveal to Special Summon from Hand/Deck, then shuffle self
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.spcost1)
    e2:SetTarget(s.sptg1)
    e2:SetOperation(s.spop1)
    c:RegisterEffect(e2)

    -- 2. Target 1 "Red-Eyes" in GY/Banished, Special Summon both and match Level
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id+1)
    e3:SetTarget(s.sptg2)
    e3:SetOperation(s.spop2)
    c:RegisterEffect(e3)
end

s.listed_series={0x3b}
s.listed_names={id}

-- Xyz Material Logic
function s.xyzval(e,c)
    -- Trả về true vì lá này có thể dùng làm 2 nguyên liệu cho bất kỳ quái thú Xyz nào
    return true 
end

-- E1 Logic: Reveal -> SpSummon -> Shuffle
function s.spcost1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return not e:GetHandler():IsPublic() end
    Duel.ConfirmCards(1-tp,e:GetHandler())
end
function s.spfilter1(c,e,tp)
    return c:IsLevelBelow(4) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_DRAGON)
        and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg1(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
        and c:IsAbleToDeck() end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        if c:IsRelateToEffect(e) then
            Duel.BreakEffect()
            Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end

-- E2 Logic: Special Summon both from GY/Banished
function s.spfilter2(c,e,tp)
    return c:IsSetCard(0x3b) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local c=e:GetHandler()
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.spfilter2(chkc,e,tp) and chkc~=c end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
            and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT)
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
            and Duel.IsExistingTarget(s.spfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,c,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter2,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,c,e,tp)
    g:AddCard(c)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,2,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) or not tc:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
    
    local g=Group.FromCards(c,tc)
    if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==2 then
        if tc:HasLevel() and c:HasLevel() then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CHANGE_LEVEL)
            e1:SetValue(tc:GetLevel())
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            c:RegisterEffect(e1)
        end
    end
end
