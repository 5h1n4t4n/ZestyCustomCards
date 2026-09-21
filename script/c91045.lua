-- Rank-Up-Magic Sky Striker Rising
-- ID: 2772337
local s,id=GetID()

function s.initial_effect(c)
    -- HIỆU ỨNG 1: Rank-Up Xyz Summon từ Extra Deck, chuyển nguyên liệu và gắn chính lá bài này làm nguyên liệu
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- HIỆU ỨNG 2: Trục xuất từ Mộ để gắn 1 lá "Sky Striker" từ Mộ hoặc vùng trục xuất làm nguyên liệu Xyz
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.mattg)
    e2:SetOperation(s.matop)
    c:RegisterEffect(e2)
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 1 (RANK-UP)
--------------------------------------------------------------------------------
function s.filter1(c,e,tp)
    local rk=c:GetRank()
    return c:IsFaceup() and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ)
        and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,rk+1)
end

function s.filter2(c,e,tp,mc,rk)
    return c:IsRankAbove(rk) and c:IsSetCard(0x115) and c:IsType(TYPE_XYZ) and mc:IsCanBeXyzMaterial(c,tp)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter1(chkc,e,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.filter1,tp,LOCATION_MZONE,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.filter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) or tc:IsControler(1-tp) or tc:IsImmuneToEffect(e) then return end
    local rk=tc:GetRank()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc,rk+1)
    local sc=g:GetFirst()
    if sc then
        local mg=tc:GetOverlayGroup()
        if #mg>0 then
            Duel.Overlay(sc,mg)
        end
        sc:SetMaterial(Group.FromCards(tc))
        Duel.Overlay(sc,Group.FromCards(tc))
        Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
        sc:CompleteProcedure()
        
        -- Gắn chính lá bài phép này (nếu còn nằm trên sân/hoạt động) vào Xyz Monster vừa triệu hồi như nguyên liệu
        if c:IsRelateToEffect(e) and not c:IsLocation(LOCATION_DECK) then
            Duel.Overlay(sc,Group.FromCards(c))
        end
    end
end

--------------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG 2 (GẮN NGUYÊN LIỆU TỪ MỘ HOẶC VÙNG TRỤC XUẤT)
--------------------------------------------------------------------------------
function s.matfilter(c)
    return c:IsSetCard(0x115) and (c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.xyzfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_XYZ)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingTarget(s.matfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
    local g=Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    local tg=g:Filter(Card.IsRelateToEffect,nil,e)
    local xyz=tg:Filter(Card.IsType,nil,TYPE_XYZ):GetFirst()
    local mat=tg:Filter(function(c) return not c:IsType(TYPE_XYZ) end,nil):GetFirst()
    if xyz and mat and xyz:IsFaceup() and not xyz:IsImmuneToEffect(e) then
        Duel.Overlay(xyz,Group.FromCards(mat))
    end
end