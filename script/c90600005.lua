-- Sky Striker Ace - Striker Typhon
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon chuẩn (3 quái thú Level 8) hoặc triệu hồi bằng "Rank-Up-Magic Sky Striker Rising"
    Xyz.AddProcedure(c,nil,8,3,s.ovfilter,aux.Stringid(id,0))
    c:EnableReviveLimit()

    -- HIỆU ỨNG 1: Quick Effect - Ngăn chặn kích hoạt của đối thủ và trục xuất úp mặt lá đó
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,{id,1})
    e1:SetCondition(s.negcon)
    e1:SetCost(aux.dxmcost(1,1,nil))
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Khi bài của đối thủ bị trục xuất úp mặt bởi hiệu ứng bài của bạn -> Thêm 1 "Sky Striker" Spell từ Deck, Mộ, hoặc vùng trục xuất lên tay
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_REMOVE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,2})
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- HIỆU ỨNG 3: Khi lá bài bạn điều khiển rời sân do hiệu ứng bài của đối thủ -> Gắn 1 lá "Sky Striker" từ Mộ hoặc vùng trục xuất làm nguyên liệu
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,3))
    e3:SetCategory(CATEGORY_LEAVE_GRAVE)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetRange(LOCATION_MZONE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,{id,3})
    e3:SetCondition(s.matcon)
    e3:SetTarget(s.mattg)
    e3:SetOperation(s.matop)
    c:RegisterEffect(e3)

    -- HIỆU ỨNG 4: Nếu lá Xyz Summon này bị phá hủy bởi bài của đối thủ -> Special Summon 1 quái "Sky Striker" từ Mộ/vùng trục xuất, rồi thêm 1 Phép "Sky Striker"
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,4))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_DESTROYED)
    e4:SetCountLimit(1,{id,4})
    e4:SetCondition(s.descon)
    e4:SetTarget(s.destg)
    e4:SetOperation(s.desop)
    c:RegisterEffect(e4)
end

--------------------------------------------------------------------------------
-- ĐIỀU KIỆN TRIỆU HỒI
--------------------------------------------------------------------------------
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ,lc,SUMMON_TYPE_XYZ,tp) and c:IsRank(7) -- Hoặc điều kiện áp dụng từ Rank-Up-Magic
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 1 (NEGATE & BANISH ÚP MẶT)
--------------------------------------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and rp==1-tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local rc=re:GetHandler()
    if chk==0 then return rc:IsRelateToEffect(re) and rc:IsAbleToRemove(tp,POS_FACEDOWN) end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,tp,0)
    if rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,tp,POS_FACEDOWN)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.Remove(rc,POS_FACEDOWN,REASON_EFFECT)
        end
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 2 (THÊM PHÉP KHI ĐỐI THỦ BỊ TRỤC XUẤT ÚP MẶT)
--------------------------------------------------------------------------------
function s.thfilter(c,tp)
    return c:IsControler(1-tp) and c:IsPosition(POS_FACEDOWN) and c:IsReason(REASON_EFFECT)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.thfilter,1,nil,tp) and re and re:GetHandler():IsControler(tp)
end

function s.skspellfilter(c)
    return c:IsSetCard(0x115) and c:IsType(TYPE_SPELL) and c:IsAbleToHand() 
        and (c:IsLocation(LOCATION_DECK) or c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.skspellfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.skspellfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 3 (GẮN NGUYÊN LIỆU KHI BÀI RỜI SÂN)
--------------------------------------------------------------------------------
function s.cfilter(c,tp)
    return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp
end

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.matfilter(c)
    return c:IsSetCard(0x115) and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and s.matfilter(chkc) end
    if chk==0 then return e:GetHandler()->IsType(TYPE_XYZ) 
        and Duel.IsExistingTarget(s.matfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        Duel.Overlay(c,Group.FromCards(tc))
    end
end

--------------------------------------------------------------------------------
-- HIỆU ỨNG 4 (SPECIAL SUMMON & THÊM BÀI KHI BỊ PHÁ HỦY)
--------------------------------------------------------------------------------
function s.descon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_EFFECT) and rp==1-tp and c:IsSummonType(SUMMON_TYPE_XYZ)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x115) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
        and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=Duel.SelectMatchingCard(tp,s.skspellfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
        if #sg>0 then
            Duel.SendtoHand(sg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,sg)
        end
    end
end