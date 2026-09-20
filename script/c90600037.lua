-- Sky Striker Special Maneuver - Paradox Gate!
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG 1: Xáo các lá từ Mộ/Vùng trục xuất vào Deck, trả bài về tay, và có thể lấy thêm Phép Sky Striker
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quick Effect trong Mộ khi có "Sky Striker" được Special Summon -> Trục xuất chính nó để Link Summon ngay lập tức
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.lkcon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.lktg)
    e2:SetOperation(s.lkop)
    c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1
--------------------------------------------------------------------------------
function s.tdfilter(c)
    return (c:IsLocation(LOCATION_GRAVE) or c:IsLocation(LOCATION_REMOVED)) and c:IsAbleToDeck()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,99,nil)
    if #g>0 then
        local ct=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        if ct>0 then
            -- Tính số lượng lá có thể trả về tay (mỗi 4 lá xáo vào Deck được trả 1 lá trên sân về tay)
            local return_count = math.floor(ct/4)
            if return_count>0 and Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
                local rg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,return_count,nil)
                if #rg>0 then
                    Duel.BreakEffect()
                    Duel.SendtoHand(rg,nil,REASON_EFFECT)
                end
            end
            
            -- Kiểm tra xem trong số các lá xáo vào Deck có từ 3 lá "Sky Striker" Spells trở lên không
            local sk_count = g:FilterCount(function(c) return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) end)
            if sk_count>=3 and Duel.IsExistingMatchingCard(function(c) return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,nil) then
                if Duel.SelectYesNo(tp, aux.Stringid(id, 2)) then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                    local sc=Duel.SelectMatchingCard(tp,function(c) return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand() end,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
                    if sc then
                        Duel.SendtoHand(sc,nil,REASON_EFFECT)
                        Duel.ConfirmCards(1-tp,sc)
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2 (QUICK EFFECT TỪ MỘ ĐỂ LINK SUMMON)
--------------------------------------------------------------------------------
function s.cfilter(c,tp)
    return c:IsControler(tp) and c:IsSetCard(0x115) and c:IsSummonType(SUMMON_TYPE_SPECIAL)
end

function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(aux.LinkSummonableFilter,tp,LOCATION_EXTRA,0,1,nil,nil) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.lkop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.LinkSummonableFilter,tp,LOCATION_EXTRA,0,nil,nil)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=g:Select(tp,1,1,nil)
        Duel.LinkSummon(tp,sg:GetFirst(),nil)
    end
end