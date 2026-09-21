-- Sky Striker Ace - Fujin
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Link Summon: 1 quái thú "Sky Striker"
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),1,1)
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Nếu được Link Summon, gửi 1 lá bài "Sky Striker" từ Deck xuống Mộ
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.lkcon)
    e1:SetCountLimit(1,{id,1})
    e1:SetTarget(s.tgtg)
    e1:SetOperation(s.tgop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Khi lá bài này gây sát thương chiến đấu cho đối thủ: Gửi 1 lá "Sky Striker" từ Deck xuống Mộ, rồi thêm 1 Phép "Sky Striker" từ Mộ hoặc vùng trục xuất lên tay
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_BATTLE_DAMAGE)
    e2:SetCondition(s.damcon)
    e2:SetTarget(s.damtg)
    e2:SetOperation(s.damop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Nếu lá bài này được dùng làm nguyên liệu cho việc Xyz Summon quái Xyz "Sky Striker": Gắn 1 lá bài "Sky Striker" từ Mộ vào quái Xyz đó làm nguyên liệu
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetCondition(s.matcon)
    e3:SetOperation(s.matop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG
--------------------------------------------------------------------------------

function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.tgfilter(c)
    return c:IsSetCard(0x115) and c:IsAbleToGrave()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.tgop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return ep~=tp
end

function s.thfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)~=0 then
        local tc=Duel.GetFirstTarget()
        if tc and tc:IsRelateToEffect(e) then
            Duel.SendtoHand(tc,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,tc)
        end
    end
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    local rc=e:GetHandler():GetReasonCard()
    return r==REASON_XYZ and rc:IsSetCard(0x115) and rc:IsType(TYPE_XYZ)
end

function s.attfilter(c)
    return c:IsSetCard(0x115) and c:IsAbleToChangePosition() -- hoặc cơ chế check gắn nguyên liệu từ Mộ
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    if not rc then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectMatchingCard(tp,function(sc) return sc:IsSetCard(0x115) and sc:IsControler(tp) and sc:IsLocation(LOCATION_GRAVE) end,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.Overlay(rc,g)
    end
end