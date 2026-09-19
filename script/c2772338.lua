-- Sky Striker Ace - Violet
-- ID: 02772338
local s,id=GetID()

function s.initial_effect(c)
    -- Always treated as a "Sky Striker Ace - Roze" card (ID: 84012625)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CHANGE_CODE)
    e0:SetValue(84012625)
    c:RegisterEffect(e0)

    -- EFFECT 1: Special Summon from Hand/GY when a "Sky Striker" monster is Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e1b=e1:Clone()
    e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e1b)

    -- EFFECT 2: (Quick Effect) Tribute + Special Summon from Extra Deck + Negate effect (+ Banishes face-down)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(aux.ReleaseCost)
    e2:SetTarget(s.exsptg)
    e2:SetOperation(s.exspop)
    c:RegisterEffect(e2)

    -- EFFECT 3: Sent from Field to GY -> Search 1 "Sky Striker" or "Rank-Up-Magic" Spell
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetCountLimit(1,id+100)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- EFFECT 1 LOGIC
--------------------------------------------------------------------------------
function s.spfilter(c,tp)
    return c:IsSetCard(0x115) and c:IsControler(tp) and c:IsFaceup()
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spfilter,1,nil,tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
    end
end

--------------------------------------------------------------------------------
-- EFFECT 2 LOGIC
--------------------------------------------------------------------------------
function s.exspfilter(c,e,tp)
    return c:IsSetCard(0x115) and c:IsType(TYPE_MONSTER)
        and Duel.GetLocationCountFromEx(tp,tp,e:GetHandler(),c)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.disfilter(c)
    return c:IsFaceup() and not c:IsDisabled()
end

function s.exsptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.exspfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.exspop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.exspfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        -- Target 1 face-up card opponent controls to negate
        local disg=Duel.GetMatchingGroup(s.disfilter,tp,0,LOCATION_ONFIELD,nil)
        if #disg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
            local sg=disg:Select(tp,1,1,nil)
            local tc=sg:GetFirst()
            if tc then
                Duel.HintSelection(sg)
                local c=e:GetHandler()
                
                -- Negate effects until the end of this turn
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

                -- Check condition: 3 or more Spells in GY -> Banish 1 card from opponent's GY face-down
                local spell_count=Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
                local rmg=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil,POS_FACEDOWN)
                if spell_count>=3 and #rmg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
                    local rm=rmg:Select(tp,1,1,nil)
                    if #rm>0 then
                        Duel.Remove(rm,POS_FACEDOWN,REASON_EFFECT)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- EFFECT 3 LOGIC
--------------------------------------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

function s.thfilter(c)
    local is_ss_spell = c:IsSetCard(0x115) and c:IsType(TYPE_SPELL)
    local is_rum_spell = c:IsSetCard(0x95) and c:IsType(TYPE_SPELL)
    return (is_ss_spell or is_rum_spell) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end