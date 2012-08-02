/* Copyright (c) 2012 Roxiware */
function formatTime(time)
{
    var hour = time.getHours();
    var meridian = (hour<12)?"am":"pm";
    if (hour==0) hour=12;
    return "%d:%02d%s".sprintf(hour % 12, time.getMinutes(), meridian);
}


function populate_news_item(overlay, news_item_id)
{
    var news_item_article = "#news_item-"+news_item_id;
    var post_date;
    overlay.attr("data", news_item_id);
    if (news_item_id != "new") {
       var upload_path=window.location;
       if (!/\/$/.test(upload_path)) {
           upload_path += "/";
       } 
       upload_path += news_item_id;
       overlay.find("form").attr("action", upload_path);
       post_date = new Date($( news_item_article +" .post_date").attr("data"));
       overlay.find("input[name=headline]").val($(news_item_article + " .headline").text());
       overlay.find("textarea[name=content]").text($(news_item_article + " .content").text());
    }
}

