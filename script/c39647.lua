-- Robin - The Star Rail Summeretto
local s,id=GetID()

s.listed_series={0x987,0x986,0x369}

function s.initial_effect(c)
    -- Must be properly Xyz Summoned
    c:EnableReviveLimit()

    -- Standard Xyz Summon
    Xyz.AddProcedure(c,s.xyzfilter,12,2)

    --------------------------------------------------
    -- Alternative Xyz Summon
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetValue(SUMMON_TYPE_XYZ)
    e1:SetCondition(s.altcon)
    e1:SetTarget(s.alttg)
    e1:SetOperation(s.altop)
    c:RegisterEffect(e1)

    --------------------------------------------------
    -- Cannot be destroyed by opponent's effects
    --------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetValue(s.indval)
    c:RegisterEffect(e2)

    --------------------------------------------------
    -- Cannot be Tributed by opponent
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_UNRELEASABLE_SUM)
    e3:SetValue(s.reltg)
    c:RegisterEffect(e3)

    local e3b=e3:Clone()
    e3b:SetCode(EFFECT_UNRELEASABLE_NONSUM)
    c:RegisterEffect(e3b)

    --------------------------------------------------
    -- Cannot be banished by opponent
    --------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCode(EFFECT_CANNOT_REMOVE)
    e4:SetValue(s.indval)
    c:RegisterEffect(e4)

    --------------------------------------------------
    -- Cannot be sent to GY by opponent
    --------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCode(EFFECT_CANNOT_TO_GRAVE)
    e5:SetValue(s.indval)
    c:RegisterEffect(e5)

    --------------------------------------------------
    -- Cannot be targeted
    --------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e6:SetValue(1)
    c:RegisterEffect(e6)

    --------------------------------------------------
    -- On Xyz Summon
    --------------------------------------------------
    local e7=Effect.CreateEffect(c)
    e7:SetDescription(aux.Stringid(id,1))
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e7:SetCode(EVENT_SPSUMMON_SUCCESS)
    e7:SetProperty(EFFECT_FLAG_DELAY)
    e7:SetCondition(s.sumcon)
    e7:SetTarget(s.sumtg)
    e7:SetOperation(s.sumop)
    c:RegisterEffect(e7)

    --------------------------------------------------
    -- Quick Effect - 3 times per turn
    --------------------------------------------------
    local e8=Effect.CreateEffect(c)
    e8:SetDescription(aux.Stringid(id,4))
    e8:SetCategory(CATEGORY_DESTROY+CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
    e8:SetType(EFFECT_TYPE_QUICK_O)
    e8:SetCode(EVENT_CHAINING)
    e8:SetRange(LOCATION_MZONE)
    e8:SetCountLimit(3,id)
    e8:SetCondition(s.qcon)
    e8:SetCost(s.qcost)
    e8:SetTarget(s.qtg)
    e8:SetOperation(s.qop)
    c:RegisterEffect(e8)
end

--------------------------------------------------
-- Standard Xyz Material
--------------------------------------------------

function s.xyzfilter(c,xyz,sumtype,tp)
    return c:IsSetCard(0x987)
        or c:IsSetCard(0x986)
        or c:IsSetCard(0x369)
end

--------------------------------------------------
-- Alternative Xyz Summon
--------------------------------------------------

function s.altmfilter(c)
    return (c:IsSetCard(0x987)
        or c:IsSetCard(0x986)
        or c:IsSetCard(0x369))
        and c:IsCanBeXyzMaterial(nil)
end

function s.fieldmat(c)
    return c:IsFaceup() and s.altmfilter(c)
end

function s.altcon(e,c,og,min,max)
    if c==nil then
        return true
    end

    local tp=c:GetControler()

    local mg1=Duel.GetMatchingGroup(
        s.fieldmat,
        tp,
        LOCATION_MZONE,
        0,
        nil
    )

    local mg2=Duel.GetMatchingGroup(
        s.altmfilter,
        tp,
        LOCATION_HAND,
        0,
        nil
    )

    return #mg1>=3
        and #mg2>=2
        and Duel.GetLocationCountFromEx(
            tp,
            tp,
            mg1,
            c
        )>0
end

function s.alttg(e,tp,eg,ep,ev,re,r,rp,chk,c,og,min,max)
    local mg1=Duel.GetMatchingGroup(
        s.fieldmat,
        tp,
        LOCATION_MZONE,
        0,
        nil
    )

    local mg2=Duel.GetMatchingGroup(
        s.altmfilter,
        tp,
        LOCATION_HAND,
        0,
        nil
    )

    if #mg1<3 or #mg2<2 then
        return false
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_XMATERIAL
    )

    local g1=mg1:Select(tp,3,3,nil)

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_XMATERIAL
    )

    local g2=mg2:Select(tp,2,2,nil)

    g1:Merge(g2)
    g1:KeepAlive()

    e:SetLabelObject(g1)

    return true
end

function s.altop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
    local g=e:GetLabelObject()

    if g then
        c:SetMaterial(g)
        Duel.Overlay(c,g)
    end
end

--------------------------------------------------
-- Protection
--------------------------------------------------

function s.indval(e,re,rp)
    return rp==1-e:GetHandlerPlayer()
end

function s.reltg(e,c)
    return c:GetControler()~=e:GetHandlerPlayer()
end

--------------------------------------------------
-- Xyz Summon Success
--------------------------------------------------

function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

function s.sumfilter(c,e,tp)
    return c:IsSetCard(0x987)
        and c:IsRace(RACE_WINGEDBEAST)
        and c:IsLevel(1)
        and c:IsAttack(0)
        and (
            c:IsAbleToHand()
            or (
                e
                and c:IsCanBeSpecialSummoned(
                    e,
                    0,
                    tp,
                    false,
                    false
                )
            )
        )
end

function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local g=Duel.GetMatchingGroup(
            s.sumfilter,
            tp,
            LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,
            0,
            nil,
            e,
            tp
        )

        return #g>=3
    end

    Duel.SetOperationInfo(
        0,
        CATEGORY_SPECIAL_SUMMON,
        nil,
        3,
        tp,
        LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED
    )

    Duel.SetOperationInfo(
        0,
        CATEGORY_TOHAND,
        nil,
        3,
        tp,
        LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED
    )
end

function s.sumop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(
        aux.NecroValleyFilter(s.sumfilter),
        tp,
        LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,
        0,
        nil,
        e,
        tp
    )

    if #g<3 then
        return
    end

    Duel.Hint(
        HINT_SELECTMSG,
        tp,
        HINTMSG_SPSUMMON
    )

    local sg=g:Select(tp,3,3,nil)

    if #sg==3 then

        local can_sp=
            Duel.GetLocationCount(tp,LOCATION_MZONE)>=3
            and not Duel.IsPlayerAffectedByEffect(
                tp,
                CARD_BLUEEYES_SPIRIT
            )
            and sg:FilterCount(
                Card.IsCanBeSpecialSummoned,
                nil,
                e,
                0,
                tp,
                false,
                false
            )==3

        local can_th=
            sg:FilterCount(
                Card.IsAbleToHand,
                nil
            )==3

        local op=0

        if can_sp and can_th then

            op=Duel.SelectOption(
                tp,
                aux.Stringid(id,2),
                aux.Stringid(id,3)
            )

        elseif can_sp then

            op=0

        elseif can_th then

            op=1

        else

            return
        end

        if op==0 then

            Duel.SpecialSummon(
                sg,
                0,
                tp,
                tp,
                false,
                false,
                POS_FACEUP
            )

        else

            Duel.SendtoHand(
                sg,
                nil,
                REASON_EFFECT
            )

            Duel.ConfirmCards(
                1-tp,
                sg
            )
        end
    end

    --------------------------------------------------
    -- Genshin / Star Rail / Halovian restriction
    --------------------------------------------------

    local e1=Effect.CreateEffect(
        e:GetHandler()
    )

    e1:SetType(EFFECT_TYPE_FIELD)

    e1:SetProperty(
        EFFECT_FLAG_PLAYER_TARGET
        +EFFECT_FLAG_CLIENT_HINT
    )

    e1:SetCode(
        EFFECT_CANNOT_SPECIAL_SUMMON
    )

    e1:SetDescription(
        aux.Stringid(id,13)
    )

    e1:SetTargetRange(1,0)
    e1:SetTarget(s.sumlimit)

    Duel.RegisterEffect(e1,tp)
end

function s.sumlimit(e,c)
    return not (
        c:IsSetCard(0x987)
        or c:IsSetCard(0x986)
        or c:IsSetCard(0x369)
    )
end

--------------------------------------------------
-- Quick Effect
--------------------------------------------------

function s.qcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp
end

--------------------------------------------------
-- Cost
--------------------------------------------------

function s.costfilter1(c)
    return c:IsSetCard(0x987)
        and c:IsMonster()
        and c:IsDiscardable()
end

function s.costfilter2(c)
    return c:IsSetCard(0x987)
        and c:IsMonster()
        and c:IsFaceup()
        and c:IsAbleToGraveAsCost()
end

function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)

    local b1=Duel.IsExistingMatchingCard(
        s.costfilter1,
        tp,
        LOCATION_HAND,
        0,
        1,
        nil
    )

    local b2=Duel.IsExistingMatchingCard(
        s.costfilter2,
        tp,
        LOCATION_MZONE,
        0,
        1,
        nil
    )

    if chk==0 then
        return b1 or b2
    end

    local op=0

    if b1 and b2 then

        op=Duel.SelectOption(
            tp,
            aux.Stringid(id,5),
            aux.Stringid(id,6)
        )

    elseif b1 then

        op=0

    else

        op=1
    end

    if op==0 then

        Duel.DiscardHand(
            tp,
            s.costfilter1,
            1,
            1,
            REASON_COST+REASON_DISCARD
        )

    else

        Duel.Hint(
            HINT_SELECTMSG,
            tp,
            HINTMSG_TOGRAVE
        )

        local g=Duel.SelectMatchingCard(
            tp,
            s.costfilter2,
            tp,
            LOCATION_MZONE,
            0,
            1,
            1,
            nil
        )

        Duel.SendtoGrave(
            g,
            REASON_COST
        )
    end
end

--------------------------------------------------
-- Special Summon filter
--------------------------------------------------

function s.qspfilter(c,e,tp)
    return c:IsSetCard(0x987)
        and c:IsLevel(1)
        and c:IsAttack(0)
        and c:IsCanBeSpecialSummoned(
            e,
            0,
            tp,
            false,
            false
        )
end

--------------------------------------------------
-- Quick Effect Target
--------------------------------------------------

function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)

    local b1=Duel.IsExistingMatchingCard(
        aux.TRUE,
        tp,
        0,
        LOCATION_HAND+LOCATION_ONFIELD,
        1,
        nil
    )

    local b2=Duel.IsChainNegatable(ev)

    local b3=
        re:GetHandler():IsRelateToEffect(re)
        and re:GetHandler():IsAbleToRemove()

    local b4=
        Duel.GetLocationCount(
            tp,
            LOCATION_MZONE
        )>0
        and Duel.IsExistingMatchingCard(
            s.qspfilter,
            tp,
            LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
            0,
            1,
            nil,
            e,
            tp
        )

    if chk==0 then
        return b1 or b2 or b3 or b4
    end

    local ops={}
    local opval={}
    local off=1

    if b1 then
        ops[off]=aux.Stringid(id,7)
        opval[off]=0
        off=off+1
    end

    if b2 then
        ops[off]=aux.Stringid(id,8)
        opval[off]=1
        off=off+1
    end

    if b3 then
        ops[off]=aux.Stringid(id,9)
        opval[off]=2
        off=off+1
    end

    if b4 then
        ops[off]=aux.Stringid(id,10)
        opval[off]=3
        off=off+1
    end

    local op=Duel.SelectOption(
        tp,
        table.unpack(ops)
    )+1

    local sel=opval[op]

    e:SetLabel(sel)

    if sel==0 then

        e:SetCategory(
            CATEGORY_DESTROY
        )

        local g=Duel.GetMatchingGroup(
            aux.TRUE,
            tp,
            0,
            LOCATION_HAND+LOCATION_ONFIELD,
            nil
        )

        Duel.SetOperationInfo(
            0,
            CATEGORY_DESTROY,
            g,
            1,
            0,
            0
        )

    elseif sel==1 then

        e:SetCategory(
            CATEGORY_NEGATE+CATEGORY_DESTROY
        )

        Duel.SetOperationInfo(
            0,
            CATEGORY_NEGATE,
            eg,
            1,
            0,
            0
        )

        if re:GetHandler():IsDestructable()
            and re:GetHandler():IsRelateToEffect(re)
        then

            Duel.SetOperationInfo(
                0,
                CATEGORY_DESTROY,
                eg,
                1,
                0,
                0
            )
        end

    elseif sel==2 then

        e:SetCategory(
            CATEGORY_REMOVE
        )

        Duel.SetOperationInfo(
            0,
            CATEGORY_REMOVE,
            eg,
            1,
            0,
            0
        )

    elseif sel==3 then

        e:SetCategory(
            CATEGORY_SPECIAL_SUMMON
        )

        Duel.SetOperationInfo(
            0,
            CATEGORY_SPECIAL_SUMMON,
            nil,
            1,
            tp,
            LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED
        )
    end
end

--------------------------------------------------
-- Quick Effect Operation
--------------------------------------------------

function s.qop(e,tp,eg,ep,ev,re,r,rp)

    local sel=e:GetLabel()

    --------------------------------------------------
    -- Destroy
    --------------------------------------------------

    if sel==0 then

        local b1=
            Duel.GetFieldGroupCount(
                tp,
                0,
                LOCATION_HAND
            )>0

        local b2=
            Duel.GetMatchingGroupCount(
                aux.TRUE,
                tp,
                0,
                LOCATION_ONFIELD,
                nil
            )>0

        local opt=0

        if b1 and b2 then

            opt=Duel.SelectOption(
                tp,
                aux.Stringid(id,11),
                aux.Stringid(id,12)
            )

        elseif b1 then

            opt=0

        elseif b2 then

            opt=1

        else

            return
        end

        if opt==0 then

            local hg=
                Duel.GetFieldGroup(
                    tp,
                    0,
                    LOCATION_HAND
                ):RandomSelect(tp,1)

            if #hg>0 then
                Duel.Destroy(
                    hg,
                    REASON_EFFECT
                )
            end

        else

            Duel.Hint(
                HINT_SELECTMSG,
                tp,
                HINTMSG_DESTROY
            )

            local fg=
                Duel.SelectMatchingCard(
                    tp,
                    aux.TRUE,
                    tp,
                    0,
                    LOCATION_ONFIELD,
                    1,
                    1,
                    nil
                )

            if #fg>0 then

                Duel.HintSelection(fg)

                Duel.Destroy(
                    fg,
                    REASON_EFFECT
                )
            end
        end

    --------------------------------------------------
    -- Negate
    --------------------------------------------------

    elseif sel==1 then

        if Duel.NegateActivation(ev)
            and re:GetHandler():IsRelateToEffect(re)
        then

            Duel.Destroy(
                eg,
                REASON_EFFECT
            )
        end

    --------------------------------------------------
    -- Banish until End Phase
    --------------------------------------------------

    elseif sel==2 then

        local tc=re:GetHandler()

        if tc
            and tc:IsRelateToEffect(re)
            and Duel.Remove(
                tc,
                POS_FACEUP,
                REASON_EFFECT+REASON_TEMPORARY
            )>0
        then

            local e1=Effect.CreateEffect(
                e:GetHandler()
            )

            e1:SetType(
                EFFECT_TYPE_FIELD
                +EFFECT_TYPE_CONTINUOUS
            )

            e1:SetCode(
                EVENT_PHASE+PHASE_END
            )

            e1:SetReset(
                RESET_PHASE+PHASE_END
            )

            e1:SetCountLimit(1)

            e1:SetLabelObject(tc)

            e1:SetOperation(
                s.retop
            )

            Duel.RegisterEffect(
                e1,
                tp
            )
        end

    --------------------------------------------------
    -- Special Summon
    --------------------------------------------------

    elseif sel==3 then

        if Duel.GetLocationCount(
            tp,
            LOCATION_MZONE
        )<=0 then

            return
        end

        Duel.Hint(
            HINT_SELECTMSG,
            tp,
            HINTMSG_SPSUMMON
        )

        local g=
            Duel.SelectMatchingCard(
                tp,
                aux.NecroValleyFilter(
                    s.qspfilter
                ),
                tp,
                LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,
                0,
                1,
                1,
                nil,
                e,
                tp
            )

        if #g>0 then

            Duel.SpecialSummon(
                g,
                0,
                tp,
                tp,
                false,
                false,
                POS_FACEUP
            )
        end
    end
end

--------------------------------------------------
-- Return banished card at End Phase
--------------------------------------------------

function s.retop(e,tp,eg,ep,ev,re,r,rp)

    local tc=e:GetLabelObject()

    if tc
        and tc:IsLocation(LOCATION_REMOVED)
    then

        Duel.ReturnToField(tc)
    end
end