-- Sky Striker Mobilize - Advanced
-- ID: 02772337
local s,id=GetID()

function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_DECKDES)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetHintTiming(0,TIMING_END_PHASE)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MMZONE,0)==0
end

function s.thfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
        Duel.ConfirmCards(1-tp,g)
        
        local spell_count=Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
        if spell_count>=3 and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 
            and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            
            Duel.BreakEffect()
            Duel.ConfirmDecktop(tp,3)
            local dg=Duel.GetDecktopGroup(tp,3)
            if #dg>0 then
                local sg=dg:Filter(function(c) return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToHand() end, nil)
                if #sg>0 then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                    local th=sg:Select(tp,1,1,nil)
                    Duel.SendtoHand(th,nil,REASON_EFFECT)
                    Duel.ConfirmCards(1-tp,th)
                    dg:Sub(th)
                end
                if #dg>0 then
                    Duel.SendtoGrave(dg,REASON_EFFECT)
                end
            end
        end
    end

    -- Giới hạn Triệu hồi Đặc biệt: chỉ được gọi quái thú "Sky Striker" trong phần còn lại của lượt
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsSetCard(0x115) and not c:IsSetCard(0x1115)
end