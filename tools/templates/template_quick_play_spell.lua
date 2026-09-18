-- ============================================================
-- Card Name: <<CARD_NAME>>
-- Passcode : <<PASSCODE>>
-- Type     : Spell / Quick-Play
-- Archetype: <<ARCHETYPE_NAME>> (0x<<SETCODE>>)
-- ============================================================
-- Effect 1: Target 1 face-up "<<ARCHETYPE_NAME>>" monster you
--           control; it gains <<ATK_VALUE>> ATK until the end
--           of this turn.
-- ============================================================
-- Quick-Play timing đến từ type bit 0x10000 trong JSON specs,
-- không phải từ effect: activation vẫn là EFFECT_TYPE_ACTIVATE
-- + EVENT_FREE_CHAIN (official ref: Book of Moon c14087893,
-- Rush Recklessly c70046172).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick-Play activation: ATK boost until end of turn
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_ATKCHANGE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)                       -- Activation effect of the Spell itself
    e1:SetCode(EVENT_FREE_CHAIN)                           -- No specific timing requirement
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)                -- Targets a card; bỏ nếu effect không target
    e1:SetTarget(s.tg_atkup)
    e1:SetOperation(s.op_atkup)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Face-up archetype monsters on the field
-- ============================================================
function s.filter_atkup(c)
    return c:IsFaceup() and c:IsSetCard(0x<<SETCODE>>)
end

-- ============================================================
-- Effect 1: Target — chkc kiểm tra card người chơi bấm chọn,
--           chk==0 kiểm tra còn mục tiêu hợp lệ hay không
-- ============================================================
function s.tg_atkup(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter_atkup(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter_atkup,tp,LOCATION_MZONE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(tp,s.filter_atkup,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Target phải còn liên hệ và còn ngửa
--           tại resolution thì mới nhận buff
-- ============================================================
function s.op_atkup(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetReset(RESETS_STANDARD_PHASE_END)             -- Hết hiệu lực cuối lượt này
        e1:SetValue(<<ATK_VALUE>>)
        tc:RegisterEffect(e1)
    end
end
