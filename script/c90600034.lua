-- Sky Striker Mobilize - Cross Resonance
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG: Special Summon từ Deck -> Link/Xyz Summon ngay lập tức -> Phá hủy 1 lá của đối thủ nếu có từ 3 Phép trở lên trong Mộ
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG
--------------------------------------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MMZONE,0)==0
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x115) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
    
    -- Kiểm tra nếu có từ 3 Phép trở lên trong Mộ thì cho phép chọn mục tiêu phá hủy của đối thủ
    local ct=Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)
    if ct>=3 and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,1,nil)
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
    end
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        -- Ngay sau khi Special Summon thành công, tiến hành Triệu hồi Link hoặc Xyz ngay lập tức
        Duel.BreakEffect()
        local g_link=Duel.GetMatchingGroup(aux.LinkSummonableFilter,tp,LOCATION_EXTRA,0,nil,nil)
        local g_xyz=Duel.GetMatchingGroup(Card.IsXyzSummonable,tp,LOCATION_EXTRA,0,nil,nil)
        
        if #g_link>0 or #g_xyz>0 then
            local op=0
            if #g_link>0 and #g_xyz>0 then
                op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
            elseif #g_link>0 then
                op=Duel.SelectOption(tp,aux.Stringid(id,1))
            else
                op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
            end
            
            if op==0 then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
                local sg=g_link:Select(tp,1,1,nil)
                Duel.LinkSummon(tp,sg:GetFirst(),nil)
            else
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
                local sg=g_xyz:Select(tp,1,1,nil)
                Duel.XyzSummon(tp,sg:GetFirst(),nil)
            end
        end
    end
    
    -- Xử lý hiệu ứng bổ sung: Nếu có từ 3 Phép trở lên trong Mộ, phá hủy 1 lá bài đã chọn của đối thủ
    local tc_des=Duel.GetFirstTarget()
    if tc_des and tc_des:IsRelateToEffect(e) and Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3 then
        Duel.BreakEffect()
        Duel.Destroy(tc_des,REASON_EFFECT)
    end
end