-- Sky Striker Maneuver - Singularity Intercept
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG: Trục xuất 1 lá "Sky Striker" của bạn và 1 lá của đối thủ (trên sân hoặc Mộ), vô hiệu hóa hiệu ứng của lá đối thủ trong lượt này
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DISABLE)
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

-- Bộ lọc cho lá "Sky Striker" của bạn (trên sân hoặc trong Mộ nếu có từ 3 Phép trở lên)
function s.myfilter(c,tp)
    if not (c:IsSetCard(0x115) and c:IsAbleToRemove()) then return false end
    local has_three = Duel.GetMatchingGroupCount(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_SPELL)>=3
    if has_three then
        return c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_GRAVE)
    else
        return c:IsLocation(LOCATION_MZONE)
    end
end

-- Đã sửa: Thêm tham số tp vào hàm oppfilter
function s.oppfilter(c,tp)
    return (c:IsLocation(LOCATION_ONFIELD) or c:IsLocation(LOCATION_GRAVE)) and c:IsControler(1-tp) and c:IsAbleToRemove()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then 
        return Duel.IsExistingTarget(s.myfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,tp)
            -- Đã sửa: Truyền tp vào cuối hàm IsExistingTarget
            and Duel.IsExistingTarget(s.oppfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil,tp)
    end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g1=Duel.SelectTarget(tp,s.myfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    -- Đã sửa: Truyền tp vào cuối hàm SelectTarget
    local g2=Duel.SelectTarget(tp,s.oppfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil,tp)
    
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g1,#g1,tp,LOCATION_ONFIELD+LOCATION_GRAVE)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    local tg=g:Filter(Card.IsRelateToEffect,nil,e)
    if #tg>0 then
        -- Trục xuất cả 2 mục tiêu đã chọn
        local rcount=Duel.Remove(tg,POS_FACEUP,REASON_EFFECT)
        if rcount>0 then
            -- Lọc ra lá bài của đối thủ vừa bị trục xuất để áp dụng hiệu ứng vô hiệu hóa
            local opp_card=tg:Filter(Card.IsControler,nil,1-tp):GetFirst()
            if opp_card then
                local c=e:GetHandler()
                -- Vô hiệu hóa hiệu ứng trên sân và các hiệu ứng được kích hoạt mang cùng tên gốc
                local code=opp_card:GetOriginalCode()
                
                -- Vô hiệu hóa tại chỗ nếu lá bài đó quay lại sân
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_FIELD)
                e1:SetCode(EFFECT_DISABLE)
                e1:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
                e1:SetTarget(s.distg)
                e1:SetLabel(code)
                e1:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e1,tp)
                
                -- Vô hiệu hóa các hiệu ứng kích hoạt mang cùng tên gốc trong lượt này
                local e2=Effect.CreateEffect(c)
                e2:SetType(EFFECT_TYPE_FIELD)
                e2:SetCode(EFFECT_DISABLE_EFFECT)
                e2:SetTargetRange(LOCATION_ONFIELD,LOCATION_ONFIELD)
                e2:SetTarget(s.distg)
                e2:SetLabel(code)
                e2:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e2,tp)
            end
        end
    end
end

function s.distg(e,c)
    return c:IsOriginalCode(e:GetLabel())
end