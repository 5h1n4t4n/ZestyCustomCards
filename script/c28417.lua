-- Sky Striker Ace - Kagutsuchi
local s,id=GetID()

s.listed_series={0x115}

function s.initial_effect(c)
    -- Must be properly Xyz Summoned
    c:EnableReviveLimit()

    -- Standard Xyz Summon: 2 Level 4 "Sky Striker" monsters
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2,s.ovfilter,aux.Stringid(id,0),1,s.altop)

    -- Special Summon Count Limit: Once per turn
    c:SetSPSummonOnce(id)

    --------------------------------------------------
    -- Effect 1: Detach 1 material; reveal top 3 cards
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE+CATEGORY_DECKDES)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(aux.dxcon(1,1))
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1,false,REGISTER_FLAG_DETACH_XMAT)

    --------------------------------------------------
    -- Effect 2: Grant Indestructible by card effects to Link Monster using this card
    --------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetCondition(s.linkcon)
    e2:SetOperation(s.linkop)
    c:RegisterEffect(e2)

    --------------------------------------------------
    -- Effect 3: Grant Double Attack to Rank 8 "Sky Striker" Xyz Monster
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.xyzcon)
    e3:SetOperation(s.xyzop)
    c:RegisterEffect(e3)
end

--------------------------------------------------
-- Alternative Xyz Summon Procedure (1 Sky Striker Link Monster)
--------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_LINK,lc,SUMMON_TYPE_XYZ,tp)
end

function s.altop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
    local g=e:GetLabelObject()
    if g then
        local mg=g:GetFirst():GetOverlayGroup()
        if #mg>0 then
            Duel.Overlay(c,mg)
        end
        c:SetMaterial(g)
        Duel.Overlay(c,g)
        g:DeleteGroup()
    end
end

--------------------------------------------------
-- Effect 1 Logic
--------------------------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
    Duel.ConfirmDecktop(tp,3)
    local g=Duel.GetDecktopGroup(tp,3)
    local sg=g:Filter(Card.IsSetCard,nil,0x115)
    
    if #sg>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local thg=sg:Select(tp,1,1,nil)
        if #thg>0 then
            Duel.SendtoHand(thg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,thg)
            g:Sub(thg)
        end
        if #g>0 then
            Duel.SendtoGrave(g,REASON_EFFECT)
        end
    else
        Duel.ShuffleDeck(tp)
    end
end

--------------------------------------------------
-- Effect 2 Logic (Link Material Protection)
--------------------------------------------------
function s.linkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_LINK and rc:IsSetCard(0x115)
end

function s.linkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
end

--------------------------------------------------
-- Effect 3 Logic (Rank 8 Xyz Material Double Attack)
--------------------------------------------------
function s.xyzcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_XYZ and rc:IsSetCard(0x115) and rc:IsRank(8)
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,3))
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_EXTRA_ATTACK)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
end