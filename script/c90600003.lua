-- Sky Striker Ace - The Fallen Automaton
-- ID: 2772337
local s,id=GetID()

--------------------------------------------------------------------------------
-- GLOBAL HOOK: Call Stack Tracing để bẻ khóa điều kiện Sky Striker
--------------------------------------------------------------------------------
if not s.global_check then
    s.global_check=true

    -- Danh sách ID các lá Phép Sky Striker yêu cầu Main Monster Zone phải trống
    local ss_spells = {
        [1475311] = true,   -- Engage!
        [99550415] = true,  -- Afterburners!
        [63166095] = true,  -- Jamming Waves!
        [51613904] = true,  -- Hornet Drones
        [6128004] = true,   -- Widow Anchor
        [25733157] = true,  -- Eagle Booster
        [90726340] = true,  -- Shark Cannon
        [31952210] = true,  -- Vector Blast
        [50920401] = true,  -- Scissors Cross
        [21976007] = true   -- Linkage!
    }

    -- Hàm "nghe lén" xem script đang gọi hàm có phải là Phép Sky Striker không
    local function is_skystriker_caller()
        for i = 2, 7 do
            local info = debug.getinfo(i, "S")
            if not info then break end
            if info.short_src then
                local id_str = info.short_src:match("c(%d+)%.lua")
                if id_str and ss_spells[tonumber(id_str)] then
                    return true
                end
            end
        end
        return false
    end

    -- Hàm kiểm tra xem The Fallen Automaton có đang ngửa trên sân hay không
    local function has_automaton(tp)
        return Duel.IsExistingMatchingCard(function(c)
            return c:IsFaceup() and c:IsCode(id) and not c:IsDisabled()
        end, tp, LOCATION_MZONE, 0, 1, nil)
    end

    -- 1. Hook hàm đếm nhóm bài chung
    local old_GetFieldGroupCount = Duel.GetFieldGroupCount
    Duel.GetFieldGroupCount = function(tp, loc1, loc2)
        if not s.hook_lock and (loc1 == LOCATION_MZONE or loc1 == LOCATION_MMZONE) and loc2 == 0 then
            s.hook_lock = true
            local bypass = is_skystriker_caller() and has_automaton(tp)
            s.hook_lock = false
            if bypass then return 0 end -- Giả lập sân trống
        end
        return old_GetFieldGroupCount(tp, loc1, loc2)
    end

    -- 2. Hook hàm đếm nhóm bài theo điều kiện (Engage thường xài hàm này)
    local old_GetMatchingGroupCount = Duel.GetMatchingGroupCount
    Duel.GetMatchingGroupCount = function(f, tp, loc1, loc2, ex, ...)
        if not s.hook_lock and (loc1 == LOCATION_MZONE or loc1 == LOCATION_MMZONE) and loc2 == 0 then
            s.hook_lock = true
            local bypass = is_skystriker_caller() and has_automaton(tp)
            s.hook_lock = false
            if bypass then return 0 end -- Giả lập sân trống
        end
        return old_GetMatchingGroupCount(f, tp, loc1, loc2, ex, ...)
    end

    -- 3. Hook hàm kiểm tra thẻ bài tồn tại (Widow Anchor, Shark Cannon thường xài)
    local old_IsExistingMatchingCard = Duel.IsExistingMatchingCard
    Duel.IsExistingMatchingCard = function(f, tp, loc1, loc2, count, ex, ...)
        if not s.hook_lock and (loc1 == LOCATION_MZONE or loc1 == LOCATION_MMZONE) and loc2 == 0 then
            s.hook_lock = true
            local bypass = is_skystriker_caller() and has_automaton(tp)
            s.hook_lock = false
            if bypass then return false end -- Báo cáo "không tìm thấy quái thú nào ở MMZ"
        end
        return old_IsExistingMatchingCard(f, tp, loc1, loc2, count, ex, ...)
    end
end

--------------------------------------------------------------------------------
-- CÁC HIỆU ỨNG CHÍNH CỦA THE FALLEN AUTOMATON
--------------------------------------------------------------------------------
function s.initial_effect(c)
    -- Điều kiện triệu hồi Link
    c:EnableReviveLimit()
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115,0x1115),2,2)

    -- HIỆU ỨNG 1: Khi được Triệu hồi Link -> Vô hiệu hóa 1 lá bài của đối thủ đến cuối lượt
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Bỏ qua điều kiện Ô Quái Thú Chính (Đã được tự động xử lý bởi Call Stack Tracing ở trên)

    -- HIỆU ỨNG 3: (Quick Effect) Gửi 1 lá "Sky Striker" -> Vô hiệu hóa & trục xuất úp
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(2,id)
    e3:SetCondition(s.discon)
    e3:SetCost(s.discost)
    e3:SetTarget(s.distg)
    e3:SetOperation(s.disop)
    c:RegisterEffect(e3)

    -- HIỆU ỨNG 4: Rút/Lấy lại 1 lá "Sky Striker" khác tên
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,2))
    e4:SetCategory(CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_REMOVE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id+100)
    e4:SetCondition(s.thcon)
    e4:SetTarget(s.thtg)
    e4:SetOperation(s.thop)
    c:RegisterEffect(e4)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and aux.NegateAnyFilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
    local g=Duel.SelectTarget(tp,aux.NegateAnyFilter,tp,0,LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() and tc:IsCanBeDisabledByEffect(e) then
        local c=e:GetHandler()
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
    end
end

function s.discon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.cfilter(c)
    return (c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToGraveAsCost()
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,e:GetHandler())
    Duel.SendtoGrave(g,REASON_COST)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsAbleToRemove(tp,POS_FACEDOWN) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local ec=re:GetHandler()
    if Duel.NegateEffect(ev) and ec and ec:IsRelateToEffect(re) then
        ec:CancelToGrave()
        Duel.Remove(ec,POS_FACEDOWN,REASON_EFFECT)
    end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:GetHandler()==e:GetHandler()
end

function s.thfilter(c,banished_group)
    if not ((c:IsSetCard(0x115) or c:IsSetCard(0x1115)) and c:IsAbleToHand()) then return false end
    return not banished_group or not banished_group:IsExists(Card.IsCode,1,nil,c:GetCode())
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,eg) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,eg)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end