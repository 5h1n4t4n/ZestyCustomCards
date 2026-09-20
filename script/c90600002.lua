-- Sky Striker Ace - Kagutsuchi
-- ID: 18199611
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon chuẩn (2 quái thú Level 4 "Sky Striker")
    Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x115),4,2,s.ovfilter,aux.Stringid(id,0),s.ovop)
    c:EnableReviveLimit()
    
    -- Chỉ được Special Summon "Sky Striker Ace - Kagutsuchi" một lần mỗi lượt
    aux.GlobalCheck(s,function()
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_SPSUMMON_SUCCESS)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1,0)
    end)

    -- HIỆU ỨNG 1: Đào 3 lá từ Deck, thêm lá "Sky Striker" lên tay và gửi phần còn lại xuống Mộ (hoặc xáo cả 3 vào Deck nếu không có)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
    e1:SetCost(aux.dxmcost(1,1,nil))
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Quái thú "Sky Striker" được Link Summon dùng lá này làm nguyên liệu không thể bị phá hủy bởi hiệu ứng bài
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_BE_MATERIAL)
    e2:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e2:SetCondition(s.efcon)
    e2:SetOperation(s.efop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Nếu dùng làm nguyên liệu cho Xyz Summon của quái Rank 8 "Sky Striker", quái đó được đánh 2 lần trong mỗi Battle Phase
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_BE_MATERIAL)
    e3:SetProperty(EFFECT_FLAG_EVENT_PLAYER)
    e3:SetCondition(s.rkcon)
    e3:SetOperation(s.rkop)
    c:RegisterEffect(e3)
end

--------------------------------------------------------------------------------
-- ĐIỀU KIỆN VÀ TRIỆU HỒI ĐẶC BIỆT
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_LINK,lc,SUMMON_TYPE_XYZ,tp)
end

function s.ovop(e,tp,chk0)
    return true
end

function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    -- Logic giới hạn 1 lần Special Summon mỗi lượt nếu cần thiết
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 1 (ĐÀO 3 LÁ TỪ DECK)
--------------------------------------------------------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<3 then return end
    Duel.ConfirmDecktop(tp,3)
    local g=Duel.GetDecktopGroup(tp,3)
    if #g>0 then
        if g:IsExists(Card.IsSetCard,1,nil,0x115) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local sg=g:FilterSelect(tp,Card.IsSetCard,1,1,nil,0x115)
            if #sg>0 then
                Duel.SendtoHand(sg,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,sg)
                g:Sub(sg)
                Duel.SendtoGrave(g,REASON_EFFECT+REASON_REVEAL)
            end
        else
            Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 2 (KHÁNG PHÁ HỦY CHO LINK MONSTER)
--------------------------------------------------------------------------------
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_LINK and rc:IsSetCard(0x115)
end

function s.efop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 3 (ĐÁNH 2 LẦN CHO RANK 8)
--------------------------------------------------------------------------------
function s.rkcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    return r==REASON_XYZ and rc:IsSetCard(0x115) and rc:IsRank(8)
end

function s.rkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local rc=c:GetReasonCard()
    local e1=Effect.CreateEffect(rc)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EXTRA_ATTACK)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    rc:RegisterEffect(e1,true)
end