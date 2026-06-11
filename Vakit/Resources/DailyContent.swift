import Foundation

/// Günlük ayet/hadis kartı içeriği. Tamamen offline; ağ gerektirmez.
struct DailyContentEntry: Identifiable {
    let id: Int
    let textTR: String
    let textEN: String
    let sourceTR: String
    let sourceEN: String
}

enum DailyContent {
    /// Günün içeriği: yılın günü mod içerik sayısı.
    static func today(for date: Date = Date()) -> DailyContentEntry {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return entries[dayOfYear % entries.count]
    }

    static let entries: [DailyContentEntry] = [
        DailyContentEntry(
            id: 1,
            textTR: "Öyleyse beni anın ki ben de sizi anayım. Bana şükredin, nankörlük etmeyin.",
            textEN: "So remember Me; I will remember you. And be grateful to Me and do not deny Me.",
            sourceTR: "Bakara Suresi, 2:152",
            sourceEN: "Surah Al-Baqarah, 2:152"
        ),
        DailyContentEntry(
            id: 2,
            textTR: "Ey iman edenler! Sabır ve namazla yardım isteyin. Şüphesiz Allah sabredenlerle beraberdir.",
            textEN: "O you who believe! Seek help through patience and prayer. Indeed, Allah is with the patient.",
            sourceTR: "Bakara Suresi, 2:153",
            sourceEN: "Surah Al-Baqarah, 2:153"
        ),
        DailyContentEntry(
            id: 3,
            textTR: "Kullarım sana beni sorduğunda, şüphesiz ben çok yakınım. Bana dua ettiğinde dua edenin duasına karşılık veririm.",
            textEN: "When My servants ask you about Me — indeed I am near. I respond to the supplication of the one who calls upon Me.",
            sourceTR: "Bakara Suresi, 2:186",
            sourceEN: "Surah Al-Baqarah, 2:186"
        ),
        DailyContentEntry(
            id: 4,
            textTR: "Dikkat edin! Kalpler ancak Allah'ı anmakla huzur bulur.",
            textEN: "Unquestionably, by the remembrance of Allah hearts are assured.",
            sourceTR: "Ra'd Suresi, 13:28",
            sourceEN: "Surah Ar-Ra'd, 13:28"
        ),
        DailyContentEntry(
            id: 5,
            textTR: "Şüphesiz zorlukla beraber bir kolaylık vardır. Evet, zorlukla beraber bir kolaylık vardır.",
            textEN: "Indeed, with hardship comes ease. Indeed, with hardship comes ease.",
            sourceTR: "İnşirah Suresi, 94:5-6",
            sourceEN: "Surah Ash-Sharh, 94:5-6"
        ),
        DailyContentEntry(
            id: 6,
            textTR: "Kim Allah'a tevekkül ederse, O kendisine yeter. Şüphesiz Allah, emrini yerine getirendir.",
            textEN: "And whoever relies upon Allah — then He is sufficient for him. Indeed, Allah will accomplish His purpose.",
            sourceTR: "Talâk Suresi, 65:3",
            sourceEN: "Surah At-Talaq, 65:3"
        ),
        DailyContentEntry(
            id: 7,
            textTR: "De ki: Ey kendilerine karşı aşırı giden kullarım! Allah'ın rahmetinden ümit kesmeyin. Şüphesiz Allah bütün günahları bağışlar.",
            textEN: "Say: O My servants who have transgressed against themselves, do not despair of the mercy of Allah. Indeed, Allah forgives all sins.",
            sourceTR: "Zümer Suresi, 39:53",
            sourceEN: "Surah Az-Zumar, 39:53"
        ),
        DailyContentEntry(
            id: 8,
            textTR: "Şüphesiz namaz, hayasızlıktan ve kötülükten alıkoyar. Allah'ı anmak elbette en büyük ibadettir.",
            textEN: "Indeed, prayer prohibits immorality and wrongdoing, and the remembrance of Allah is greater.",
            sourceTR: "Ankebût Suresi, 29:45",
            sourceEN: "Surah Al-Ankabut, 29:45"
        ),
        DailyContentEntry(
            id: 9,
            textTR: "Şüphesiz ben Allah'ım. Benden başka ilah yoktur. Bana kulluk et ve beni anmak için namaz kıl.",
            textEN: "Indeed, I am Allah. There is no deity except Me, so worship Me and establish prayer for My remembrance.",
            sourceTR: "Tâhâ Suresi, 20:14",
            sourceEN: "Surah Ta-Ha, 20:14"
        ),
        DailyContentEntry(
            id: 10,
            textTR: "Andolsun, eğer şükrederseniz elbette size nimetimi artırırım.",
            textEN: "If you are grateful, I will surely increase you in favor.",
            sourceTR: "İbrahim Suresi, 14:7",
            sourceEN: "Surah Ibrahim, 14:7"
        ),
        DailyContentEntry(
            id: 11,
            textTR: "Kararını verdiğin zaman artık Allah'a tevekkül et. Şüphesiz Allah, tevekkül edenleri sever.",
            textEN: "And when you have decided, then rely upon Allah. Indeed, Allah loves those who rely upon Him.",
            sourceTR: "Âl-i İmrân Suresi, 3:159",
            sourceEN: "Surah Aal-i-Imran, 3:159"
        ),
        DailyContentEntry(
            id: 12,
            textTR: "Şüphesiz namaz, müminlere belirli vakitlerde farz kılınmıştır.",
            textEN: "Indeed, prayer has been decreed upon the believers at specified times.",
            sourceTR: "Nisâ Suresi, 4:103",
            sourceEN: "Surah An-Nisa, 4:103"
        ),
        DailyContentEntry(
            id: 13,
            textTR: "Müminler gerçekten kurtuluşa ermiştir. Onlar ki namazlarında derin saygı içindedirler.",
            textEN: "Successful indeed are the believers — those who humble themselves in their prayer.",
            sourceTR: "Mü'minûn Suresi, 23:1-2",
            sourceEN: "Surah Al-Mu'minun, 23:1-2"
        ),
        DailyContentEntry(
            id: 14,
            textTR: "Sabret! Çünkü Allah, iyilik edenlerin mükâfatını zayi etmez.",
            textEN: "And be patient, for indeed, Allah does not allow the reward of those who do good to be lost.",
            sourceTR: "Hûd Suresi, 11:115",
            sourceEN: "Surah Hud, 11:115"
        ),
        DailyContentEntry(
            id: 15,
            textTR: "Asra yemin olsun ki, insan gerçekten ziyan içindedir. Ancak iman edip salih amel işleyenler, birbirlerine hakkı ve sabrı tavsiye edenler müstesna.",
            textEN: "By time, indeed mankind is in loss — except those who believe and do righteous deeds and advise each other to truth and to patience.",
            sourceTR: "Asr Suresi, 103:1-3",
            sourceEN: "Surah Al-Asr, 103:1-3"
        ),
        DailyContentEntry(
            id: 16,
            textTR: "Rabbiniz şöyle buyurdu: Bana dua edin, duanıza karşılık vereyim.",
            textEN: "And your Lord says: Call upon Me; I will respond to you.",
            sourceTR: "Mü'min Suresi, 40:60",
            sourceEN: "Surah Ghafir, 40:60"
        ),
        DailyContentEntry(
            id: 17,
            textTR: "Kim zerre kadar bir hayır işlerse onu görür. Kim de zerre kadar bir kötülük işlerse onu görür.",
            textEN: "So whoever does an atom's weight of good will see it, and whoever does an atom's weight of evil will see it.",
            sourceTR: "Zilzâl Suresi, 99:7-8",
            sourceEN: "Surah Az-Zalzalah, 99:7-8"
        ),
        DailyContentEntry(
            id: 18,
            textTR: "Allah hiçbir kimseyi gücünün yetmediği bir şeyle yükümlü kılmaz.",
            textEN: "Allah does not burden a soul beyond that it can bear.",
            sourceTR: "Bakara Suresi, 2:286",
            sourceEN: "Surah Al-Baqarah, 2:286"
        ),
        DailyContentEntry(
            id: 19,
            textTR: "Ameller ancak niyetlere göredir. Herkese ancak niyet ettiği vardır.",
            textEN: "Actions are but by intentions, and every person will have only what they intended.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 20,
            textTR: "İslam beş esas üzerine kurulmuştur: Allah'tan başka ilah olmadığına ve Muhammed'in O'nun elçisi olduğuna şahitlik etmek, namaz kılmak, zekât vermek, hacca gitmek ve Ramazan orucunu tutmak.",
            textEN: "Islam is built upon five: testifying that there is no deity but Allah and that Muhammad is His Messenger, establishing prayer, giving zakat, pilgrimage, and fasting Ramadan.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 21,
            textTR: "Kolaylaştırın, zorlaştırmayın. Müjdeleyin, nefret ettirmeyin.",
            textEN: "Make things easy and do not make them difficult. Give glad tidings and do not repel people.",
            sourceTR: "Hadis — Buhârî",
            sourceEN: "Hadith — Bukhari"
        ),
        DailyContentEntry(
            id: 22,
            textTR: "Müslüman, elinden ve dilinden müslümanların güvende olduğu kimsedir.",
            textEN: "The Muslim is the one from whose tongue and hand the Muslims are safe.",
            sourceTR: "Hadis — Buhârî",
            sourceEN: "Hadith — Bukhari"
        ),
        DailyContentEntry(
            id: 23,
            textTR: "Sizin en hayırlınız, Kur'an'ı öğrenen ve öğretendir.",
            textEN: "The best of you are those who learn the Quran and teach it.",
            sourceTR: "Hadis — Buhârî",
            sourceEN: "Hadith — Bukhari"
        ),
        DailyContentEntry(
            id: 24,
            textTR: "Temizlik imanın yarısıdır.",
            textEN: "Cleanliness is half of faith.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 25,
            textTR: "Kim bir hayra vesile olursa, ona o hayrı yapanın sevabı kadar sevap vardır.",
            textEN: "Whoever guides someone to goodness will have a reward like the one who did it.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 26,
            textTR: "Allah'a en sevimli amel, az da olsa devamlı olanıdır.",
            textEN: "The most beloved deeds to Allah are those done consistently, even if small.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 27,
            textTR: "Müminin hâli ne hoştur! Her hâli kendisi için hayırlıdır. Bolluğa kavuşursa şükreder, bu onun için hayır olur. Darlığa düşerse sabreder, bu da onun için hayır olur.",
            textEN: "How wonderful is the affair of the believer, for all of it is good. If ease comes to him, he is grateful, and that is good for him. If hardship befalls him, he is patient, and that is good for him.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 28,
            textTR: "Beş vakit namaz, birinizin kapısının önünden akan ve içinde her gün beş defa yıkandığı bir nehir gibidir; üzerinde hiç kir bırakmaz.",
            textEN: "The five daily prayers are like a river flowing at your door in which you bathe five times a day; no dirt remains on you.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 29,
            textTR: "Kıyamet günü kulun ilk hesaba çekileceği ameli namazdır.",
            textEN: "The first deed for which a servant will be held accountable on the Day of Judgment is prayer.",
            sourceTR: "Hadis — Tirmizî",
            sourceEN: "Hadith — Tirmidhi"
        ),
        DailyContentEntry(
            id: 30,
            textTR: "Kim sabah namazını kılarsa Allah'ın koruması altındadır.",
            textEN: "Whoever prays the morning prayer is under the protection of Allah.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 31,
            textTR: "Dua ibadetin özüdür.",
            textEN: "Supplication is the essence of worship.",
            sourceTR: "Hadis — Tirmizî",
            sourceEN: "Hadith — Tirmidhi"
        ),
        DailyContentEntry(
            id: 32,
            textTR: "Güçlü mümin, zayıf müminden daha hayırlı ve Allah'a daha sevimlidir. Bununla birlikte her ikisinde de hayır vardır.",
            textEN: "The strong believer is better and more beloved to Allah than the weak believer, though there is good in both.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 33,
            textTR: "Hiçbiriniz, kendisi için istediğini kardeşi için de istemedikçe gerçek anlamda iman etmiş olmaz.",
            textEN: "None of you truly believes until he loves for his brother what he loves for himself.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 34,
            textTR: "Güzel söz sadakadır.",
            textEN: "A good word is charity.",
            sourceTR: "Hadis — Buhârî & Müslim",
            sourceEN: "Hadith — Bukhari & Muslim"
        ),
        DailyContentEntry(
            id: 35,
            textTR: "Allah sizin suretlerinize ve mallarınıza bakmaz; fakat kalplerinize ve amellerinize bakar.",
            textEN: "Allah does not look at your appearance or wealth, but He looks at your hearts and your deeds.",
            sourceTR: "Hadis — Müslim",
            sourceEN: "Hadith — Muslim"
        ),
        DailyContentEntry(
            id: 36,
            textTR: "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver ve bizi ateş azabından koru.",
            textEN: "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.",
            sourceTR: "Bakara Suresi, 2:201",
            sourceEN: "Surah Al-Baqarah, 2:201"
        ),
    ]
}
