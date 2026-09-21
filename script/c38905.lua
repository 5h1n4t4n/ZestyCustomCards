-- The Legendary Battle of the Red-Eyes
local s,id=GetID()
function s.initial_effect(c)
    -- Activate: Negate activation & Destroy
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x3b}

-- Condition: Opponent activates effect while you control a "Red-Eyes" monster
function s.cfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x3b)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainNegatable(ev)
        and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

-- Filter Dragon monsters in Hand, Deck, GY, or Banished
function s.revfilter(c)
    return c:IsMonster() and c:IsRace(RACE_DRAGON)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        if Duel.Destroy(eg,REASON_EFFECT)>0 then
            -- Optional follow-up effect
            if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
                Duel.BreakEffect()
                local rev_tp=false
                local rev_opp=false

                -- Turn Player reveals 1 Dragon
                local g_tp=Duel.GetMatchingGroup(s.revfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
                if #g_tp>0 then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
                    local sg_tp=g_tp:Select(tp,1,1,nil)
                    if #sg_tp>0 then
                        Duel.ConfirmCards(1-tp,sg_tp)
                        rev_tp=true
                    end
                end

                -- Opponent reveals 1 Dragon
                local g_opp=Duel.GetMatchingGroup(s.revfilter,1-tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
                if #g_opp>0 then
                    Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_CONFIRM)
                    local sg_opp=g_opp:Select(1-tp,1,1,nil)
                    if #sg_opp>0 then
                        Duel.ConfirmCards(tp,sg_opp)
                        rev_opp=true
                    end
                end

                -- Players who did not reveal take 1000 damage
                if not rev_tp then
                    Duel.Damage(tp,1000,REASON_EFFECT)
                end
                if not rev_opp then
                    Duel.Damage(1-tp,1000,REASON_EFFECT)
                end

                -- If both players revealed, each loses 500 LP (Đã sửa bằng Duel.SetLP)
                if rev_tp and rev_opp then
                    Duel.SetLP(tp,Duel.GetLP(tp)-500)
                    Duel.SetLP(1-tp,Duel.GetLP(1-tp)-500)
                end
            end
        end
    end
end